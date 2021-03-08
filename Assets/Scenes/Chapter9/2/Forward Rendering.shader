// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//前向渲染
Shader "Unity Shaders Book/Chapter 9/Forward Rendering" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		//Bass Pass
		Pass {
			// 设置渲染路径标签 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			// 保证光照衰减等光照变量被正确赋值
			#pragma multi_compile_fwdbase	
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				//_WorldSpaceLightPos0得到平行光方向
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//计算场景中的环境光  只希望计算一次，因此后面的Pass就不再计算这部分  与之类似的还有物体的自发光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//对应平行光，我们在Bass Pass中处理最亮的那个，无平行光娜美BasePass就当成全黑处理
				//每一个光源5个属性：位置，方向，颜色，强度以及衰减
				//对应BasePass来所，处理的逐像素光源一定是平行光（根据理论图解）
				//_LightColor0得到平行光颜色和强度（是颜色和强度相乘的结果） 
			 	fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

			 	fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
			 	fixed3 halfDir = normalize(worldLightDir + viewDir);
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				// 平行光无衰减，所以直接令衰减值为1
				fixed atten = 1.0;
				
				return fixed4(ambient + (diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
		//Additonal Pass
		//和Bass Pass差不多，一般是去掉环境光，自发光，逐顶点光照，SH光照部分
		//处理的光源类型可能是平行光，点光源 聚光灯
		//除了颜色和强度我们可以依然使用_LightColor0来得到，位置，方向和衰减需要根据光源类型分别计算
		Pass {
			// Pass for other pixel lights
			Tags { "LightMode"="ForwardAdd" }
			//开启混合模式
			//不一定是One One，可以自己设置
			Blend One One
		
			CGPROGRAM
			
			// 保证访问到正确的光照变量
			#pragma multi_compile_fwdadd
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				//判断了当前处理的逐像素光源的类型
				//判断是否定义了USING_DIRECTIONAL_LIGHT，如果当前前向渲染Pass处理的光源类型是平行光，那么Unity底层渲染引擎就会定义USING_DIRECTIONAL_LIGHT
				#ifdef USING_DIRECTIONAL_LIGHT
				//平行光的话，光源方向可以直接由_WorldSpaceLightPos0.xyz得到
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
				//如果是点光源或聚光灯，那么_WorldSpaceLightPos0.xyz表示的是世界空间下的光源位置，
				//这样就使用向量相减，得到光源方向
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
				
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				//处理不同光源的衰减
				#ifdef USING_DIRECTIONAL_LIGHT
					//如果是平行光，衰减值为1
					fixed atten = 1.0;
				#else
					//点光源
					#if defined (POINT)
						//世界坐标转为光源空间的坐标
						//对衰减纹理的采样都是使用光源空间到点到光源中心的距离平方来作为采样坐标
				        float3 lightCoord = mul(_LightMatrix0/*世界空间转为光源空间，可用于采样cookie和光强衰减纹理*/, float4(i.worldPos, 1)).xyz;
				        fixed atten = tex2D(_LightTexture0/*衰减纹理*/, dot(lightCoord, lightCoord/*计算到光源中心的距离的平方，一个标量*/).rr/*我们对这个标量进行.rr操作相当于构建了一个二维矢量，这个二维矢量每个分量的值都是这个标量值，由此得到一个二维采样坐标*/).UNITY_ATTEN_CHANNEL;
				    //聚光灯
					#elif defined (SPOT)
				        float4 lightCoord = mul(_LightMatrix0, float4(i.worldPos, 1));
						//聚光灯计算公式
						//由于聚光灯有更多的角度等要求，因此为了得到衰减值，除了需要对衰减纹理采样外，还需要对聚光灯的范围、张角和方向进行判断
						//此时衰减纹理存储到了_LightTextureB0中，这张纹理和点光源中的_LightTexture0是等价的
						//聚光灯的_LightTexture0存储的不再是基于距离的衰减纹理，而是一张基于张角范围的衰减纹理
				        fixed atten = (lightCoord.z > 0)/*聚光灯的张角范围小于180°，因此如果lightCoord.z <= 0的话它肯定不会被照亮，衰减值就直接是0。*/ * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5/*我们希望在纹理坐标中心作为原点，中心为1，边缘为0*/).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #else
				        fixed atten = 1.0;
				    #endif
				#endif

				return fixed4((diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Specular"
}

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//消融效果
Shader "Unity Shaders Book/Chapter 15/Dissolve" {
	Properties {
		_BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0//控制消融程度，当值为0时，物体正常，为1时，物体完全消融
		_LineWidth("Burn Line Width", Range(0.0, 0.2)) = 0.1//模拟烧焦效果时的线宽，值越大，火焰边缘的蔓延范围越广
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1)//对应火焰边缘的颜色值
		_BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1)//对应火焰边缘的颜色值
		_BurnMap("Burn Map", 2D) = "white"{}//噪声纹理
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			//模型正面和背面都会被渲染，因为消融会导致裸露模型内部的构造，只渲染正面会出现错误的结果
			Cull Off
			
			CGPROGRAM
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			fixed _BurnAmount;
			fixed _LineWidth;
			sampler2D _MainTex;
			sampler2D _BumpMap;
			fixed4 _BurnFirstColor;
			fixed4 _BurnSecondColor;
			sampler2D _BurnMap;
			
			float4 _MainTex_ST;
			float4 _BumpMap_ST;
			float4 _BurnMap_ST;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float2 uvBumpMap : TEXCOORD1;
				float2 uvBurnMap : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
				SHADOW_COORDS(5)
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				//计算三张纹理对应的纹理坐标
				o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				//得到模型空间到切线空间的变换矩阵
				TANGENT_SPACE_ROTATION;
  				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;//把光源方向从模型空间变换到切线空间
  				
  				o.worldPos = mul(_Object2World, v.vertex).xyz;//计算世界空间下的顶点位置
  				//计算世界空间下的阴影纹理采样坐标
  				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;//对噪声纹理进行采样
				
				clip(burn.r - _BurnAmount);//结果小于0，剔除
				// Equal to 
	//				if ((burn.r - _BurnAmount) < 0.0) {
	//					discard;
	//				}
				float3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));
				
				fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;//材质反射率
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//环境光颜色
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));//漫反射颜色

				fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);//t为1时，表示该像素处于消融边界处，为0时，表示像素为正常颜色
				fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);//使用t混合两种火焰颜色
				burnColor = pow(burnColor, 5);//为了更接近烧焦效果，使用pow函数处理
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);//得到衰减值
				fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));//使用t混合正常光照（环境光+漫反射）和烧焦效果
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
		
		// 自定义的一个阴影投射Pass，防止阴影穿帮
		Pass {
			Tags { "LightMode" = "ShadowCaster" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_shadowcaster
			
			#include "UnityCG.cginc"
			
			fixed _BurnAmount;
			sampler2D _BurnMap;
			float4 _BurnMap_ST;
			
			struct v2f {
				V2F_SHADOW_CASTER;//内置宏 定义阴影投射需要定义的变量
				float2 uvBurnMap : TEXCOORD1;
			};
			
			v2f vert(appdata_base v) {
				v2f o;
				//使用这个函数完成剩下的事情，必须使用v作为输入结构体，且v中必须包括顶点位置v.vertex和v.normal,//我们可以直接使用内置的appdat_base
				//进行顶点动画时，我们可以在顶点着色器中直接修改v.vertex
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
				//剔除片元
				clip(burn.r - _BurnAmount);
				
				SHADOW_CASTER_FRAGMENT(i)//自动完成阴影投射部分，把结果输出到深度图和阴影投射纹理中
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 14/Toon Shading" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Ramp ("Ramp Texture", 2D) = "white" {}//控制漫反射色调的渐变纹理
		_Outline ("Outline", Range(0, 1)) = 0.1//控制轮廓线宽度
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)//轮廓线颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1)//高光反射颜色
		_SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01//计算高光反射时使用的阈值，越大高光区域越大
	}
    SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		//渲染背面的三角面片
		Pass {
			NAME "OUTLINE"
			//剔除正面
			Cull Front
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			float _Outline;
			fixed4 _OutlineColor;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			}; 
			
			struct v2f {
			    float4 pos : SV_POSITION;
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				float4 pos = mul(UNITY_MATRIX_MV, v.vertex); //把顶点和法线从模型空间变换到视角空间
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				normal.z = -0.5;//设置法线z分量，为了避免背面扩张后的顶点挡住正面的片面
				pos = pos + float4(normalize(normal)/*归一化法线*/, 0) * _Outline;//将顶点沿其方向扩张，得到扩张后的顶点坐标
				o.pos = mul(UNITY_MATRIX_P, pos);//将顶点从视角空间变换到裁剪空间
				
				return o;
			}
			
			float4 frag(v2f i) : SV_Target { 
				return float4(_OutlineColor.rgb, 1);               
			}
			
			ENDCG
		}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }//为了让光照变量可以被正确赋值
			
			Cull Back
		
			CGPROGRAM
		
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdbase
		
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Ramp;
			fixed4 _Specular;
			fixed _SpecularScale;
		
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 
		
			struct v2f {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				o.worldNormal  = mul(UNITY_MATRIX_MVP, v.normal);
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			float4 frag(v2f i) : SV_Target { 
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
				
				fixed4 c = tex2D (_MainTex, i.uv);
				fixed3 albedo = c.rgb * _Color.rgb;//材质反射率
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//环境光照
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);//计算当前世界坐标下的阴影值
				
				fixed diff =  dot(worldNormal, worldLightDir);
				diff = (diff * 0.5 + 0.5) * atten/*阴影值*/;//半兰伯特漫反射系数
				
				fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;//漫反射光照
				
				fixed spec = dot(worldNormal, worldHalfDir);//计算Blinn-Phong高光反射必要的一步
				fixed w = fwidth(spec) * 2.0;//使用fwidth函数选择邻域像素之间的近似导数值
				//smoothstep表示当spec + _SpecularScale - 1小于-w时，返回0，大于w时返回1，中间的话就是0-1之间插值
				fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale)/*控制_SpecularScale为0时候消除高光反射*/;
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
		
			ENDCG
		}
	}
	FallBack "Diffuse"
}

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Mask Texture" {
	Properties {
		//漫反射颜色
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//漫反射纹理（主纹理）
		_MainTex ("Main Tex", 2D) = "white" {}
		//法线纹理
		_BumpMap ("Normal Map", 2D) = "bump" {}
		//控制法线纹理影响度的系数
		_BumpScale("Bump Scale", Float) = 1.0
		//高光反射遮罩纹理
		_SpecularMask ("Specular Mask", 2D) = "white" {}
		//控制遮罩影响度的系数
		_SpecularScale ("Specular Scale", Float) = 1.0
		//高光反射纹理
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		//高光反射区域大小
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			//_MainTex和_BumpMap和_SpecularMask的共同使用的纹理属性变量
			//这意味我们如果改变主纹理的平铺系数和偏移系数会影响3个纹理的采样
			//如果每个纹理都使用一个的话，很快顶点着色器的插值寄存器就会被占满
			//很多时候我们让多个纹理使用同一种平铺和位移操作
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float _BumpScale;
			sampler2D _SpecularMask;
			float _SpecularScale;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 lightDir: TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy/*平铺系数*/ + _MainTex_ST.zw/*偏移*/;
				//得到模型空间到切线空间的变换矩阵
				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
			 	fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				//材质反射率
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				//环境部分
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//漫反射部分
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
				//
			 	fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
			 	// 使用遮罩纹理的r分量进行高光反射遮罩，得到高光反射遮罩系数来控制高光反射的强度
			 	fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
			 	// 计算高光反射的强度    BlinnPhong模型公式
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss) * specularMask;
			
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 10/Single Texture" {
	Properties {
		//用来控制物体的整体声调
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//声明了一个名为_MainTexts的纹理
		_MainTex ("Main Tex", 2D) = "white" /*默认属性 全白*/{}
		
		_Specular ("Specular", Color) = (1, 1, 1, 1)
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
			//名字不是任意起的，我们需要使用纹理名_ST的声明方式来声明某个纹理的属性(ST是(scale)和(translation)的简写)
			//_MainTex_ST.xy存储的是缩放值 _MainTex_ST.zw存储的是偏移值
			//在unity的面板上通过调节Tilling和Offest调节材质的这些属性
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				//模型的第一组纹理坐标
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				
				float3 worldPos : TEXCOORD1;
				//用于存储纹理坐标  用来使用该坐标进行纹理采样
				float2 uv : TEXCOORD2;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				
				//先对顶点纹理坐标进行_MainTex_ST.xy缩放，再使用_MainTex_ST.zw进行属性偏移得到uv坐标
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				// 或者使用 都是一样道理
//				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				// Use the texture to sample the diffuse color
				//纹素值*颜色=材质反射率
				fixed3 albedo = tex2D(_MainTex/*要进行采样的纹理*/, i.uv/*纹理坐标 返回计算得到的纹素值*/).rgb * _Color.rgb;
				//和环境光相乘得到环境光部分
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				return fixed4(ambient/*环境光部分*/ + diffuse/*漫反射部分*/ + specular/*高光反射部分*/, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}

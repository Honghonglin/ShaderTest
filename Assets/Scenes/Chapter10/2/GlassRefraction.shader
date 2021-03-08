// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//玻璃Shader  半透明物體
Shader "Unity Shaders Book/Chapter 10/Glass Refraction" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}//玻璃材質紋理
		_BumpMap ("Normal Map", 2D) = "bump" {}//玻璃法綫紋理
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}//模擬反射的環境紋理
		_Distortion ("Distortion", Range(0, 100)) = 10//用於控制模擬折射時的扭曲程度
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0//控制折射程度 為0時，只包含反射 為1時，只包含折射
	}
	SubShader {
		// Queue設置隊列，保證透明物體被正確渲染，不透明物體在之前被渲染
		//RenderType爲了在使用著色器替換時，物體可以在需要時被正確渲染  通常發生在我們需要得到攝像機的深度和法綫紋理時
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		
		// GrabPass關鍵詞定義了一個抓取屏幕圖像的pass
		// 字符串名稱決定我們抓取到的屏幕圖像會被存儲到哪一個紋理中
		GrabPass { "_RefractionTex" }
		
		Pass {		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;//對應了在GrabPass時指定的紋理名稱
			//在對屏幕圖像的采樣坐標進行偏移時使用該變量
			float4 _RefractionTex_TexelSize;//得到該問了的紋素大小  例如大小為256*512的紋理，紋素大小為（1/256，1/512）
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float2 texcoord: TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4; 
			};
			
			v2f vert (a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				//得到對應被抓取的屏幕圖像采樣坐標
				o.scrPos = ComputeGrabScreenPos(o.pos);
				
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
				
				float3 worldPos = mul(_Object2World, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {		
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				// 得到切綫空間下的法綫方向
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));	
				
				// 計算切綫空間下的偏移
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
				
				// 得到世界空間下的法綫方向
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 reflDir = reflect(-worldViewDir, bump);
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
				//混合反射和折射
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
	}
	
	FallBack "Diffuse"
}

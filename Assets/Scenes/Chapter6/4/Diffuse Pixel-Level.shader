// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//这是旧版的由于我用的是原来的版本，所以就不更新了
//得到光滑的光照效果
//存在问题：在光照无法到达的区域 模型的外光通常是全黑的，没有任何明暗变化
//这会使模型的背光区域看起来就像一个平面一样，失去了模型细节表现
//实际上我们可以通过添加环境光来得到非全黑的效果，但是即便这样任然无法解决背光面明暗一样的缺点
//改善技术：半兰伯特光照模型
Shader "Unity Shaders Book/Chapter 6/Diffuse Pixel-Level" {
	Properties {
		//控制漫反射颜色
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Diffuse;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
			};
			//顶点着色器不需要计算光照模型，只需要把世界空间下的法线传递给片元着色器即可
			v2f vert(a2v v) {
				v2f o;
				// Transform the vertex from object space to projection space
				o.pos =  mul(UNITY_MATRIX_MVP,v.vertex);

				// Transform the normal from object space to world space
				o.worldNormal = mul(v.normal, (float3x3)_World2Object);

				return o;
			}
			//片元着色器需要计算漫反射光照模型
			fixed4 frag(v2f i) : SV_Target {
				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// Get the normal in world space
				fixed3 worldNormal = normalize(i.worldNormal);
				// Get the light direction in world space
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
				
				fixed3 color = ambient + diffuse;
				
				return fixed4(color, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Diffuse"
}

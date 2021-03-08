// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//高光模型逐顶点模型
//问题：高光部分不平滑，主要因为高光反射部分的计算是非线性的，而在顶点着色器中计算光照再进行插值的过程是线性的
//破坏了原计算的非线性关系，就会出现较大的视觉问题
//改进方法：逐像素来计算高光反射
Shader "Unity Shaders Book/Chapter 6/Specular Vertex-Level" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		//控制材质的高光反射颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		//控制高光区域的大小
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Pass { 
			//指明该Pass的光照模式
			//LightMode标签是Pass标签的一种，用于定义该Pass在Unity的光照流水线中的角色
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			//为了在Shader中使用Properties语句块中声明的属性
			//颜色属性的范围在0到1之间，因此我们可以使用fixed精度的变量来存储它
			fixed4 _Diffuse;
			fixed4 _Specular;
			//范围很大，使用float精度来存储
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				fixed3 color : COLOR;
			};
			
			v2f vert(a2v v) {
				v2f o;
				// Transform the vertex from object space to projection space
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				
				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// Transform the normal from object space to world space
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)_World2Object));
				// Get the light direction in world space
				//指向光源（光源相对与这个物体的矢量方向）
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
				
				// 计算入射光线方向关于表面法线的反射方向
				//得到反射方向
				fixed3 reflectDir = normalize(reflect(-worldLightDir/*通过取反得到光源指向交界处的矢量*/, worldNormal));
				// 得到视角方向（相对与这个物体的）
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz/*得到摄像机在世界空间中的位置*/ - mul(_Object2World/*模型空间到世界空间变换矩阵*/, v.vertex).xyz);
				
				//  高光部分计算
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);
				
				o.color = ambient + diffuse + specular;
							 	
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				return fixed4(i.color, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}

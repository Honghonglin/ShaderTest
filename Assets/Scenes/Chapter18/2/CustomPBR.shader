Shader "Unity Shaders Book/Chapter 18/Custom PBR" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5//控制材质的粗糙度
		_SpecColor("Specular",Color)=(0.2,0.2,0.2)//控制材质的高光反射颜色
		_SpecGlossMap("Specular (RGB) Smoothness (A)",2D)="white"{}//RGB通道控制材质的高光反射颜色，A通道控制材质的粗糙度
		_BumpScale("Bump Scale",Float)=1.0//控制法线纹理的凹凸程度
		_BumpMap("Normal Map",2D)="bump"{}//材质的法线纹理
		_EmissionColor("Color",Color)=(0,0,0)//控制材质自发光颜色
		_EmissionMap("Emission",2D)="white"{}//控制材质自发光颜色
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 300
		
		Pass{
		Tags{"LightMode"="ForwardBase"}
		CGPROGRAM
		// Use shader model 3.0 target, to get nicer looking lighting
//指明使用Shader Target3.0，这是因为基于物理渲染涉及了较多的公式，因此需要较多的数学指令来进行计算，这可能会超过Shader Target2.0对指令数目的规定
		#pragma target 3.0
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
		#include "Lighting.cginc"


		fixed4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed _Glossiness;
		sampler2D _SpecGlossMap;
		float _BumpScale;
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		fixed4 _EmissionColor;
		sampler2D _EmissionMap;

		struct v2f{
			float4 pos:SV_POSITION;
			float2 uv:TEXCOORD0;
			float4 TtoW0:TEXCOORD1;
			float4 TtoW1:TEXCOORD2;
			float4 TtoW2:TEXCOORD3;
			SHADOW_COORDS(4)//#include "AutoLight.cginc"
			UNITY_FOG_COORDS(5)//#include "Lighting.cginc"
		};

		struct a2v {
			float4 vertex : POSITION;
			float4 tangent : TANGENT; 
			float3 normal : NORMAL; 
			float2 texcoord : TEXCOORD0; 
		};
		v2f vert(a2v v){
			v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f,o);

			o.pos=mul(UNITY_MATRIX_MVP,v.vertex);
			o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);

			float3 worldPos=mul(_Object2World,v.vertex);
			float3 worldNormal=UnityObjectToWorldNormal(v.normal);
			float3 worldTangent=UnityObjectToWorldDir(v.tangent.xyz);
			float3 worldBinormal=cross(worldNormal, worldTangent)* v.tangent.w;

			o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
			o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
			o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  

			TRANSFER_SHADOW(o);

			UNITY_TRANSFER_FOG(o, o.pos);

			return o;
		}
		//依照 Eric Heitz[12]ᨀ出的按 Height-Correlated Masking and Shadowing 方式组合的 Smith-Joint 阴影-遮掩函数
		inline half CustomSmithJointGGXVisibilityTerm(half NdotL, half NdotV, half roughness){
		// Original formulation:
		// lambda_v = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5f;
		// lambda_l = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5f;
		// G = 1 / (1 + lambda_v + lambda_l);
		// Approximation of the above formulation (simplify the sqrt, not mathematically correct but close enough)
		half a2 = roughness * roughness;
		half lambdaV = NdotL * (NdotV * (1 - a2) + a2);
		half lambdaL = NdotV * (NdotL * (1 - a2) + a2);
		return 0.5f / (lambdaV + lambdaL + 1e-5f);
		}
		//依照基于 GGX 模型的法线分布函数
		inline half CustomGGXTerm(half NdotH, half roughness) {
		half a2 = roughness * roughness;
		half d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
		return 1/UNITY_PI * a2 / (d * d + 1e-7f);
		}
		//依照 Schlick 菲涅耳近似等式
		inline half3 CustomFresnelTerm(half3 c, half cosA) {
		half t = pow(1 - cosA, 5);
		return c + (1 - c) * t;
		}

		inline half3 CustomFresnelLerp(half3 c0, half3 c1, half cosA) {
		half t = pow(1 - cosA, 5);
		return lerp (c0, c1, t);
		}
		//对于漫反射项，我们选择使用 Disney BRDF 中的漫反射项实现，CustomDisneyDiffuseTerm函数的实现（依照 Disney BRDF 中的漫反射项公式）
		//inline 的作用是用于告诉编译器应该尽可能使用内联调用的方式来调用该函数，减少函数调用的开销。
		inline half3 CustomDisneyDiffuseTerm(half NdotV, half NdotL, half LdotH, half roughness, half3 baseColor) {
			half fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
			// Two schlick fresnel term
			half lightScatter = (1 + (fd90 - 1) * pow(1 - NdotL, 5));
			half viewScatter = (1 + (fd90 - 1) * pow(1 - NdotV, 5));
			return baseColor * 1/UNITY_PI * lightScatter * viewScatter;//UNITY_INV_PI是圆周率π的倒数。  
		}
		half4 frag(v2f i) : SV_Target {
			///// Prepare all the inputs
			half4 specGloss = tex2D(_SpecGlossMap, i.uv);
			specGloss.a *= _Glossiness;
			half3 specColor = specGloss.rgb * _SpecColor.rgb;//高光反射颜色
			half roughness = 1 - specGloss.a;//粗糙度
			half oneMinusReflectivity = 1 - max(max(specColor.r, specColor.g), specColor.b);//主要是为了计算掠射角的反射颜色，从而得到更好的菲涅耳反射效果
			half3 diffColor = _Color.rgb * tex2D(_MainTex, i.uv).rgb * oneMinusReflectivity;//漫反射颜色
			half3 normalTangent = UnpackNormal(tex2D(_BumpMap, i.uv));
			normalTangent.xy *= _BumpScale;
			normalTangent.z = sqrt(1.0 - saturate(dot(normalTangent.xy, normalTangent.xy)));
			half3 normalWorld = normalize(half3(dot(i.TtoW0.xyz, normalTangent),dot(i.TtoW1.xyz, normalTangent), dot(i.TtoW2.xyz, normalTangent)));//世界空间下的法线方向
			float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
			half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos)); // Defined in UnityCG.cginc  光源方向
			half3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos)); // Defined in UnityCG.cginc	观察方向
			half3 reflDir = reflect(-viewDir, normalWorld);//反射方向
			UNITY_LIGHT_ATTENUATION(atten, i, worldPos); // Defined in AutoLight.cginc	计算阴影和光照衰减值
			///// Compute BRDF terms
			//开始计算BRDF光照模型
			//计算公式中的各个点乘项
			half3 halfDir = normalize(lightDir + viewDir);
			half nv = saturate(dot(normalWorld, viewDir));
			half nl = saturate(dot(normalWorld, lightDir));
			half nh = saturate(dot(normalWorld, halfDir));
			half lv = saturate(dot(lightDir, viewDir));
			half lh = saturate(dot(lightDir, halfDir));

			//计算BRDF中的漫反射项
			half3 diffuseTerm = CustomDisneyDiffuseTerm(nv, nl, lh, roughness, diffColor);

			// Specular term
			//高光反射项
			half V = CustomSmithJointGGXVisibilityTerm(nl, nv, roughness);//可见性项 V，是阴影-遮掩函数除以高光反射项的分母部分后的结果
			half D = CustomGGXTerm(nh, roughness * roughness);//法线分布项 D
			half3 F = CustomFresnelTerm(specColor, lh);//菲涅耳反射项 F
			half3 specularTerm = F * V * D;//高光反射项就是把 V、D 和 F 相乘后的结果。

			// Emission term
			half3 emisstionTerm = tex2D(_EmissionMap, i.uv).rgb * _EmissionColor.rgb;//从自发光纹理中进行采样再乘以自发光颜色

			// 计算基于图像的光照部分（IBL）：
			half perceptualRoughness = roughness * (1.7 - 0.7 * roughness);
			half mip = perceptualRoughness * 6;//6表明了整个粗糙度范围内多级渐远纹理的总级数
			//unity_SpecCube0 包含了该物体周围当前活跃的反射探针（Reflection Probe）中所包含的环境贴图
			//Unity 会根据Window -> Lighting -> Skybox 中的设置，在场景中生成一个默认的反射探针
			//此时 unity_SpecCube0中包含的就是自定义天空盒的环境贴图
			//如果我们在场景中放置了其他反射探针，Unity 则会根据相关设置和物体所在的位置自动把距离该物体最近的一个或几个反射探针数据传递给 Shader
			half4 envMap = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, mip); // Defined in HLSLSupport.cginc 使用该级数和反射方向来对环境贴图进行采样。
			half grazingTerm = saturate((1 - roughness) + (1 - oneMinusReflectivity));//掠射颜色，掠射颜色 grazingTerm 是由材质粗糙度和之前计算得到的oneMinusReflectivity 共同决定的
			half surfaceReduction = 1.0 / (roughness * roughness + 1.0);//使用了由粗糙度计算得到的 surfaceReduction 参数进一步对 IBL 的进行修正
			//尽管 grazingTerm 被声明为单一维数的 half 变量，在传递给 CustomFresnelLerp 时它会自动被转换成 half3 类型的变量
			half3 indirectSpecular = surfaceReduction * envMap.rgb * CustomFresnelLerp(specColor,grazingTerm, nv);//我们对高光反射颜色 specColor 和掠射颜色grazingTerm 进行菲涅耳插值


			// Combine all togather
			half3 col = emisstionTerm + UNITY_PI * (diffuseTerm + specularTerm) * _LightColor0.rgb * nl * atten + indirectSpecular;
			UNITY_APPLY_FOG(i.fogCoord, c.rgb); // Defined in UnityCG.cginc 添加雾效的影响
			return half4(col, 1);
		}
		
		
		ENDCG
}

		Pass{
		Tags{"LightMode"="ForwardAdd"}
		CGPROGRAM
		// Use shader model 3.0 target, to get nicer looking lighting
//指明使用Shader Target3.0，这是因为基于物理渲染涉及了较多的公式，因此需要较多的数学指令来进行计算，这可能会超过Shader Target2.0对指令数目的规定
		#pragma target 3.0
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_fwdbase
		#pragma multi_compile_fog
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
		#include "Lighting.cginc"


		fixed4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed _Glossiness;
		sampler2D _SpecGlossMap;
		float _BumpScale;
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		fixed4 _EmissionColor;
		sampler2D _EmissionMap;

		struct v2f{
			float4 pos:SV_POSITION;
			float2 uv:TEXCOORD0;
			float4 TtoW0:TEXCOORD1;
			float4 TtoW1:TEXCOORD2;
			float4 TtoW2:TEXCOORD3;
			SHADOW_COORDS(4)//#include "AutoLight.cginc"
			UNITY_FOG_COORDS(5)//#include "Lighting.cginc"
		};

		struct a2v {
			float4 vertex : POSITION;
			float4 tangent : TANGENT; 
			float3 normal : NORMAL; 
			float2 texcoord : TEXCOORD0; 
		};
		v2f vert(a2v v){
			v2f o;
			UNITY_INITIALIZE_OUTPUT(v2f,o);

			o.pos=mul(UNITY_MATRIX_MVP,v.vertex);
			o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);

			float3 worldPos=mul(_Object2World,v.vertex);
			float3 worldNormal=UnityObjectToWorldNormal(v.normal);
			float3 worldTangent=UnityObjectToWorldDir(v.tangent.xyz);
			float3 worldBinormal=cross(worldNormal, worldTangent)* v.tangent.w;

			o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
			o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
			o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  

			TRANSFER_SHADOW(o);

			UNITY_TRANSFER_FOG(o, o.pos);

			return o;
		}
		//对于漫反射项，我们选择使用 Disney BRDF 中的漫反射项实现，CustomDisneyDiffuseTerm函数的实现（依照 Disney BRDF 中的漫反射项公式）
		//inline 的作用是用于告诉编译器应该尽可能使用内联调用的方式来调用该函数，减少函数调用的开销。
		inline half3 CustomDisneyDiffuseTerm(half NdotV, half NdotL, half LdotH, half roughness, half3 baseColor) {
			half fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
			// Two schlick fresnel term
			half lightScatter = (1 + (fd90 - 1) * pow(1 - NdotL, 5));
			half viewScatter = (1 + (fd90 - 1) * pow(1 - NdotV, 5));
			return baseColor * 1/UNITY_PI * lightScatter * viewScatter;//UNITY_INV_PI是圆周率π的倒数。  
		}
		//依照 Eric Heitz[12]ᨀ出的按 Height-Correlated Masking and Shadowing 方式组合的 Smith-Joint 阴影-遮掩函数
		inline half CustomSmithJointGGXVisibilityTerm(half NdotL, half NdotV, half roughness){
		// Original formulation:
		// lambda_v = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5f;
		// lambda_l = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5f;
		// G = 1 / (1 + lambda_v + lambda_l);
		// Approximation of the above formulation (simplify the sqrt, not mathematically correct but close enough)
		half a2 = roughness * roughness;
		half lambdaV = NdotL * (NdotV * (1 - a2) + a2);
		half lambdaL = NdotV * (NdotL * (1 - a2) + a2);
		return 0.5f / (lambdaV + lambdaL + 1e-5f);
		}
		//依照基于 GGX 模型的法线分布函数
		inline half CustomGGXTerm(half NdotH, half roughness) {
		half a2 = roughness * roughness;
		half d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
		return 1/UNITY_PI * a2 / (d * d + 1e-7f);
		}
		//依照 Schlick 菲涅耳近似等式
		inline half3 CustomFresnelTerm(half3 c, half cosA) {
		half t = pow(1 - cosA, 5);
		return c + (1 - c) * t;
		}

		//inline half3 CustomFresnelLerp(half3 c0, half3 c1, half cosA) {
		//half t = pow(1 - cosA, 5);
		//return lerp (c0, c1, t);
		//}
		half4 frag(v2f i) : SV_Target {
			///// Prepare all the inputs
			half4 specGloss = tex2D(_SpecGlossMap, i.uv);
			specGloss.a *= _Glossiness;
			half3 specColor = specGloss.rgb * _SpecColor.rgb;//高光反射颜色
			half roughness = 1 - specGloss.a;//粗糙度
			half oneMinusReflectivity = 1 - max(max(specColor.r, specColor.g), specColor.b);//主要是为了计算掠射角的反射颜色，从而得到更好的菲涅耳反射效果
			half3 diffColor = _Color.rgb * tex2D(_MainTex, i.uv).rgb * oneMinusReflectivity;//漫反射颜色
			half3 normalTangent = UnpackNormal(tex2D(_BumpMap, i.uv));
			normalTangent.xy *= _BumpScale;
			normalTangent.z = sqrt(1.0 - saturate(dot(normalTangent.xy, normalTangent.xy)));
			half3 normalWorld = normalize(half3(dot(i.TtoW0.xyz, normalTangent),dot(i.TtoW1.xyz, normalTangent), dot(i.TtoW2.xyz, normalTangent)));//世界空间下的法线方向
			float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
			half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos)); // Defined in UnityCG.cginc  光源方向
			half3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos)); // Defined in UnityCG.cginc	观察方向
			half3 reflDir = reflect(-viewDir, normalWorld);//反射方向
			UNITY_LIGHT_ATTENUATION(atten, i, worldPos); // Defined in AutoLight.cginc	计算阴影和光照衰减值
			///// Compute BRDF terms
			//开始计算BRDF光照模型
			//计算公式中的各个点乘项
			half3 halfDir = normalize(lightDir + viewDir);
			half nv = saturate(dot(normalWorld, viewDir));
			half nl = saturate(dot(normalWorld, lightDir));
			half nh = saturate(dot(normalWorld, halfDir));
			half lv = saturate(dot(lightDir, viewDir));
			half lh = saturate(dot(lightDir, halfDir));

			//计算BRDF中的漫反射项
			half3 diffuseTerm = CustomDisneyDiffuseTerm(nv, nl, lh, roughness, diffColor);

			// Specular term
			//高光反射项
			half V = CustomSmithJointGGXVisibilityTerm(nl, nv, roughness);//可见性项 V，是阴影-遮掩函数除以高光反射项的分母部分后的结果
			half D = CustomGGXTerm(nh, roughness * roughness);//法线分布项 D
			half3 F = CustomFresnelTerm(specColor, lh);//菲涅耳反射项 F
			half3 specularTerm = F * V * D;//高光反射项就是把 V、D 和 F 相乘后的结果。

			// Emission term
			//half3 emisstionTerm = tex2D(_EmissionMap, i.uv).rgb * _EmissionColor.rgb;//从自发光纹理中进行采样再乘以自发光颜色

			//// 计算基于图像的光照部分（IBL）：
			//half perceptualRoughness = roughness * (1.7 - 0.7 * roughness);
			//half mip = perceptualRoughness * 6;//6表明了整个粗糙度范围内多级渐远纹理的总级数
			////unity_SpecCube0 包含了该物体周围当前活跃的反射探针（Reflection Probe）中所包含的环境贴图
			////Unity 会根据Window -> Lighting -> Skybox 中的设置，在场景中生成一个默认的反射探针
			////此时 unity_SpecCube0中包含的就是自定义天空盒的环境贴图
			////如果我们在场景中放置了其他反射探针，Unity 则会根据相关设置和物体所在的位置自动把距离该物体最近的一个或几个反射探针数据传递给 Shader
			//half4 envMap = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, mip); // Defined in HLSLSupport.cginc 使用该级数和反射方向来对环境贴图进行采样。
			//half grazingTerm = saturate((1 - roughness) + (1 - oneMinusReflectivity));//掠射颜色，掠射颜色 grazingTerm 是由材质粗糙度和之前计算得到的oneMinusReflectivity 共同决定的
			//half surfaceReduction = 1.0 / (roughness * roughness + 1.0);//使用了由粗糙度计算得到的 surfaceReduction 参数进一步对 IBL 的进行修正
			////尽管 grazingTerm 被声明为单一维数的 half 变量，在传递给 CustomFresnelLerp 时它会自动被转换成 half3 类型的变量
			//half3 indirectSpecular = surfaceReduction * envMap.rgb * CustomFresnelLerp(specColor,grazingTerm, nv);//我们对高光反射颜色 specColor 和掠射颜色grazingTerm 进行菲涅耳插值


			// Combine all togather
			half3 col = UNITY_PI * (diffuseTerm + specularTerm) * _LightColor0.rgb * nl * atten;
			//UNITY_APPLY_FOG(i.fogCoord, c.rgb); // Defined in UnityCG.cginc 添加雾效的影响
			return half4(col, 1);
		}
		ENDCG
}
	}
	FallBack "Legacy Shaders/Diffuse"
}
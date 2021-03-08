Shader "Unity Shaders Book/Chapter 17/Normal Extrusion" {
	Properties {
		_ColorTint ("Color Tint", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		_Amount ("Extrusion Amount", Range(-0.5, 0.5)) = 0.1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 300
		
		CGPROGRAM
		
		// surf - which surface function.
		// CustomLambert - which lighting model to use.
		// vertex:myvert - use custom vertex modification function.
		// finalcolor:mycolor - use custom final color modification function.
		// addshadow - generate a shadow caster pass. Because we modify the vertex position, the shder needs special shadows handling.
		// addshadow告诉Unity要生成一个该表面着色器对应的阴影投射Pass
		// exclude_path:deferred/exclude_path:prepas - do not generate passes for deferred/legacy deferred rendering path.
		//exclude_path:deferred/exclude_path:prepas告诉Unity不要为延迟渲染路径生成想要的Pass，默认下会为所有支持的渲染路径生成Pass
		// nometa - do not generate a “meta” pass (that’s used by lightmapping & dynamic global illumination to extract surface information).
		//nometa取消对提取元数据的Pass的生成
		#pragma surface surf CustomLambert vertex:myvert finalcolor:mycolor addshadow exclude_path:deferred exclude_path:prepass nometa
		#pragma target 3.0
		
		fixed4 _ColorTint;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		half _Amount;
		
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};
		//自定义顶点修改函数
		void myvert (inout appdata_full v) {
			v.vertex.xyz += v.normal * _Amount;
		}
		//表面函数
		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb;
			o.Alpha = tex.a;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
		}
		//自定义光照函数
		half4 LightingCustomLambert (SurfaceOutput s, half3 lightDir, half atten) {
			//实现简单的兰伯特漫反射
			half NdotL = dot(s.Normal, lightDir);
			half4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * (NdotL * atten);
			c.a = s.Alpha;
			return c;
		}
		//颜色修改函数
		void mycolor (Input IN, SurfaceOutput o, inout fixed4 color) {
			color *= _ColorTint;
		}
		
		ENDCG
	}
	FallBack "Legacy Shaders/Diffuse"
}

Shader "Unity Shaders Book/Chapter 17/Bumped Diffuse" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 300
		
		CGPROGRAM
		//编译指令 #pragma surface用于指明该编译指令是用于定义表面着色器的  surf表示使用的表面函数
		//Lambert表示使用的光照模型
		//一个对象的表面属性定义了它的反射率，光滑率，透明度等，表面函数就用于定义这些表面属性
		#pragma surface surf Lambert
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _BumpMap;
		fixed4 _Color;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};
		//函数形式
		//1.void surf (Input IN, inout SurfaceOutput o)
		//2.void surf (Input IN, inout SurfaceOutputStandard o)
		//3.void surf (Input IN, inout SurfaceOutputStandardSpecular o)
		//Input结构体中定义新的变量，SurfaceOutput中的变量是提前声明好的，不可以增加也不可以减少（如果没有对某些变量赋值则使用默认值）
		void surf (Input IN/*使用它来设置各种表面属性，包含了许多表面属性的数据来源*/, inout SurfaceOutput o/*把这些表面属性输出在这个结构体中，再传递给光照函数计算光照结果*/) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);//uv_MainTex，uv_BumpMap为内置变量，uv2_MainTex表明使用次纹理坐标集合
			o.Albedo = tex.rgb * _Color.rgb;
			o.Alpha = tex.a * _Color.a;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
		}
		
		ENDCG
	} 
	
	FallBack "Legacy Shaders/Diffuse"
}

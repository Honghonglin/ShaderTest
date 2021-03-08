// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 12/Bloom" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Bloom ("Bloom (RGB)", 2D) = "black" {}//模糊后的高亮区域
		_LuminanceThreshold ("Luminance Threshold", Float) = 0.5
		_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _Bloom;
		float _LuminanceThreshold;
		float _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;
		};	
		//提取较亮区域需要使用的顶点着色器
		v2f vertExtractBright(appdata_img v) {
			v2f o;
			
			o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
			
			o.uv = v.texcoord;
					 
			return o;
		}
		
		fixed luminance(fixed4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}
		//提取较亮区域需要使用的片元着色器
		fixed4 fragExtractBright(v2f i) : SV_Target {
			fixed4 c = tex2D(_MainTex, i.uv);
			fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);//采样得到的亮度值减去阀值，并截取到0~1范围内
			
			return c * val;//相乘，如果小于阈值，就会返回0，那这个片元就没得，所有整体效果就是的大提取后的两部区域
		}
		
		struct v2fBloom {
			float4 pos : SV_POSITION; 
			half4 uv : TEXCOORD0;//存储两个纹理的纹理坐标
		};		
		//混合亮部图像和原图像时使用的顶点着色器和片元着色器
		v2fBloom vertBloom(appdata_img v) {
			v2fBloom o;
			
			o.pos = mul (UNITY_MATRIX_MVP,v.vertex);
			//因为要进行平台差异化处理所以要分开
			o.uv.xy = v.texcoord;		
			o.uv.zw = v.texcoord;
			//判断是不是DirectX平台
			#if UNITY_UV_STARTS_AT_TOP
			//判断是否开启抗锯齿			
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w;//如果是就对除了主纹理之外的纹理翻转y，这里的w就是亮度纹理的y
			#endif
				     
			return o; 
		}
		
		fixed4 fragBloom(v2fBloom i) : SV_Target {
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);//混合
		} 
		
		ENDCG
		
		ZTest Always Cull Off ZWrite Off
		
		Pass {  
			CGPROGRAM  
			#pragma vertex vertExtractBright  
			#pragma fragment fragExtractBright  
			
			ENDCG  
		}
		//使用的GaussianBlur中定义的Name，注意GAUSSIAN_BLUR_VERTICAL要大写，因为它会自动转换为大写
		UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_VERTICAL"
		
		UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_HORIZONTAL"
		
		Pass {  
			CGPROGRAM  
			#pragma vertex vertBloom  
			#pragma fragment fragBloom  
			
			ENDCG  
		}
	}
	FallBack Off
}

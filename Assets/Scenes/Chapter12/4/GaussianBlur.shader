// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 12/Gaussian Blur" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0//越大，模糊程度越高，但是采样数不会受到影响，但是过大会造成虚影
	}
	SubShader {
		//CGINCLUDE和ENDCG类似于c++中的头文件功能，由于高斯模糊需要定义两个Pass，但是它们
		//使用的片元着色器代码完全相同，使用这个语句能避免我们写两个一样的片元着色器函数
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;  
		half4 _MainTex_TexelSize;
		float _BlurSize;//控制高斯模糊中邻域的大小，即控制模糊范围，控制采样距离，在高斯维度不变的情况下，_BlurSize越大，模糊程度越高，采样数却不受影响
		  
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv[5]: TEXCOORD0;//使用5*5大小的高斯核对原图像进行高斯模糊，5*5的二位高斯核可以才拆分成两个大小为5为的纹理坐标数组,结果一样
		};
		  
		v2f vertBlurVertical(appdata_img v) {
			v2f o;
			o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
			
			half2 uv = v.texcoord;
			
			o.uv[0] = uv;//存储当前的采样纹理，而剩下的四个坐标则是高斯模糊中对领域采样时使用的纹理坐标
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
					 
			return o;
		}
		
		v2f vertBlurHorizontal(appdata_img v) {
			v2f o;
			o.pos =  mul(UNITY_MATRIX_MVP,v.vertex);
			
			half2 uv = v.texcoord;
			
			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
					 
			return o;
		}
		
		fixed4 fragBlur(v2f i) : SV_Target {
			float weight[3] = {0.4026, 0.2442, 0.0545};//由对称性和公式得出，只要3个权重就可以了
			
			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			
			for (int it = 1; it < 3; it++) {
				sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];//5个元素的一维数值
				sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
			}
			
			return fixed4(sum, 1.0);
		}
		    
		ENDCG
		
		ZTest Always Cull Off ZWrite Off
		
		Pass {
			//使用NAME语义定义了Pass的名字
			//由于高斯模糊是很常见的图像处理操作，很多屏幕特效都是建立在它的基础上的
			//为Pass定义名字，可以在其他Shader中直接通过它们的名字来使用该Pass，不需要写重复代码
			NAME "GAUSSIAN_BLUR_VERTICAL"
			
			CGPROGRAM
			  
			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
			  
			ENDCG  
		}
		
		Pass {
			  
			NAME "GAUSSIAN_BLUR_HORIZONTAL"
			
			CGPROGRAM  
			
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
			
			ENDCG
		}
	} 
	FallBack "Diffuse"
}

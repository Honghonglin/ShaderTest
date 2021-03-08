// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 12/Edge Detection" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Pass {  
			ZTest Always Cull Off ZWrite Off
			
			CGPROGRAM
			
			#include "UnityCG.cginc"
			
			#pragma vertex vert  
			#pragma fragment fragSobel
			
			sampler2D _MainTex;  
			//例如一张512*512大小的纹理，该值为1/512，由于卷积需要对相邻区域内的纹理进行采样，因此我们需要利用_MainTex_TexelSize来计算各个相邻区域的纹理坐标
			uniform half4 _MainTex_TexelSize;//_***_TexelSize是Unity为我们提供的访问xxx纹理对应的每个纹素的大小
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;
			
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv[9] : TEXCOORD0;//sobel算子采样时需要9个领域的纹理坐标
			};
			  
			v2f vert(appdata_img v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				
				half2 uv = v.texcoord;
				
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
						 
				return o;
			}
			//得到像素亮度值
			fixed luminance(fixed4 color) {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
			}
			//这里我们仅仅用了屏幕颜色来作为检测依据，实际上还要用上物体的纹理，阴影等信息
			//为了得到更准确的边缘信息，我们往往会在屏幕的深度纹理和法线纹理上进行边缘检测
			half Sobel(v2f i) {
				//卷积核翻转后
				const half fanGx[9] = {1,  0,  -1,
									2,  0,  -2,
									1,  0,  -1};
				const half fanGy[9] = {1, 2, 1,
									0,  0,  0,
									-1,  -2,  -1};		
				
				half texColor;
				//整体的梯度值为根号（edgrX^2+edgeY^2） 为了简化我们直接使用abs（edgrX）+abs（edgeY）
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++) {
					texColor = luminance(tex2D(_MainTex, i.uv[it]));//得到每个像素的亮度值
					edgeX += texColor * fanGx[it];//加上乘以对应的翻转后的卷积值
					edgeY += texColor * fanGy[it];
				}
				
				half edge = 1 - abs(edgeX) - abs(edgeY);//1-整体梯度值，越小表示越可能是边缘
				
				return edge;
			}
			
			fixed4 fragSobel(v2f i) : SV_Target {
				half edge = Sobel(i);//调用sobel函数计算1-当前像素的梯度值
				
				fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);//计算背景为原图的颜色值
				fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);//计算纯色下的颜色值
				return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);//使用边缘强度决定得到的最终的像素值
 			}
			
			ENDCG
		} 
	}
	FallBack Off
}

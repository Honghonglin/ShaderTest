// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 11/Image Sequence Animation" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Image Sequence", 2D) = "white" {}//包含了所有关键帧图像的纹理
    	_HorizontalAmount ("Horizontal Amount", Float) = 4//图像水平方向包含的关键帧个数
    	_VerticalAmount ("Vertical Amount", Float) = 4//图像竖直方向包含的关键帧个数
    	_Speed ("Speed", Range(1, 100)) = 30//控制帧动画的播放速度
	}
	SubShader {
		//由于序列帧通常时透明纹理，使用我们需要设置Pass的相关状态，来渲染透明效果
		//由于序列帧图像通常包含了透明通道，因此可以被当成一个半透明对象
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			
			#pragma vertex vert  
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _HorizontalAmount;
			float _VerticalAmount;
			float _Speed;
			  
			struct a2v {  
			    float4 vertex : POSITION; 
			    float2 texcoord : TEXCOORD0;
			};  
			
			struct v2f {  
			    float4 pos : SV_POSITION;
			    float2 uv : TEXCOORD0;
			};  
			
			v2f vert (a2v v) {  
				v2f o;  
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);  
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  
				return o;
			}  
			
			fixed4 frag (v2f i) : SV_Target {
				float time = floor(_Time.y * _Speed);  //模拟时间
				float row = floor(time / _HorizontalAmount);// time/_HorizontalAmount
				float column = time - row * _HorizontalAmount;///time%_HorizontalAmount 作为列索引
				//这个地方就是把片元uv坐标转化为帧图像的相对位置，列数学公式就明白了  见本目录下图片
				//起始为左上角的帧图片
				half2 uv = float2(i.uv.x /_HorizontalAmount, i.uv.y / _VerticalAmount);
				uv.x += column / _HorizontalAmount;
				uv.y -= row / _VerticalAmount;
				uv.y+=1;
				uv.y-=1/_VerticalAmount;
				//起始为左下角的帧图片
				//half2 uv = i.uv + half2(column, -row);
				//uv.x /=  _HorizontalAmount;
				//uv.y /= _VerticalAmount;
				
				fixed4 c = tex2D(_MainTex, uv);
				c.rgb *= _Color;
				
				return c;
			}
			
			ENDCG
		}  
	}
	FallBack "Transparent/VertexLit"
}

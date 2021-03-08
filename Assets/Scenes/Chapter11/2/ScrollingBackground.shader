// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//http://opengameart.org 纹理资源网站
Shader "Unity Shaders Book/Chapter 11/Scrolling Background" {
	Properties {
		_MainTex ("Base Layer (RGB)", 2D) = "white" {}//第一层的背景纹理（较远
		_DetailTex ("2nd Layer (RGB)", 2D) = "white" {}//第二层的背景纹理（较近
		_ScrollX ("Base layer Scroll Speed", Float) = 1.0//对应第一层的水平滚动速度
		_Scroll2X ("2nd layer Scroll Speed", Float) = 1.0//对应第二层的水平滚动速度
		_Multiplier ("Layer Multiplier", Float) = 1//控制纹理的整体亮度
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			sampler2D _DetailTex;
			float4 _MainTex_ST;
			float4 _DetailTex_ST;
			float _ScrollX;
			float _Scroll2X;
			float _Multiplier;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
			};
			
			v2f vert (a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);//模型变裁剪
				//计算背景纹理的纹理坐标
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex)/*//使用内置宏来计算平铺和偏移后的纹理坐标*/ + frac(float2(_ScrollX, 0.0) * _Time.y/*使用时间控制水平方向上坐标进行偏移，以此达到滚动效果*/)/*得到小数部分的函数*/;
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);//采样
				fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);
				
				fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);//使用第二层纹理的透明通道混合两张纹理
				c.rgb *= _Multiplier;//通过乘_Multiplier调节背景亮度
				
				return c;
			}
			
			ENDCG
		}
	}
	FallBack "VertexLit"
}

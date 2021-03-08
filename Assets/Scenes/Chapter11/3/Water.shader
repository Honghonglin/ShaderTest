// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 11/Water" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}//河流纹理
		_Color ("Color Tint", Color) = (1, 1, 1, 1)//控制整体颜色
		_Magnitude ("Distortion Magnitude", Float) = 1//控制水流波动的幅度
 		_Frequency ("Distortion Frequency", Float) = 1//控制波动频率
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10//控制波长的倒数
 		_Speed ("Speed", Float) = 0.5//控制河流纹理的移动速度
	}
	SubShader {
		// Need to disable batching because of the vertex animation
		//透明效果设置较为合适
		//DisableBatching 指明是否对SubShader使用批处理
		//需要禁用批处理功能的SubShader包含了模型空间的顶点动画的Shader
		//这是因为批处理会合并所有相关的模型，而这些偶像各自的模型空间就丢失
		//在这个SubShader中我们需要在物体的哦行空间下对顶点进行偏移 具体见下
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off//让物体每个面都可以显示
			
			CGPROGRAM  
			#pragma vertex vert 
			#pragma fragment frag
			
			#include "UnityCG.cginc" 
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert(a2v v) {
				v2f o;
				
				float4 offset;//顶点位移量
				offset.yzw = float3(0.0, 0.0, 0.0);
				//对顶点的x方向进行偏移
				offset.x = sin(_Frequency * _Time.y/*控制正选函数的频率和移动*/ + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength/*让每个位置具有不同的位移*/) * _Magnitude;
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex + offset/*为顶点坐标加上偏移*/);
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv +=  float2(0.0, _Time.y * _Speed);//控制水平方向上的纹理动画
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed4 c = tex2D(_MainTex, i.uv);
				c.rgb *= _Color.rgb;//添加颜色控制
				
				return c;
			} 
			
			ENDCG
		}
	}
	//使用FallBack "VertexLit"得到错误的阴影效果
	// "Transparent/VertexLit"没有定义ShadowCaster Pass，所以不会有阴影
	FallBack "Transparent/VertexLit"
}

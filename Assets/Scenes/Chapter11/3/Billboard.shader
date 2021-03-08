// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//广告牌牌技术：根据视角方向来旋转一种被纹理着色的多边形，使得多边形看起来总是面对摄像机
//本质：构建一个旋转矩阵，基向量通常由表面法线（视角方向），指向上的方向，指向右的方向
//还需指定一个描点，在旋转过程不变，来确定多边形在空间的位置
Shader "Unity Shaders Book/Chapter 11/Billboard" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}//广告牌显示的透明纹理
		_Color ("Color Tint", Color) = (1, 1, 1, 1)//整体颜色
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1//用于调整固定法线还是固定指定向上的方向，即约束垂直方向的程度 
	}
	SubShader {
		// 广告牌技术中，我们需要使用物体的模型空间下的位置来作为描点进行计算
		//取消批处理会造成性能下降，增加DrawCall，因此我们应该避免使用模型空间下的绝对位置
		//优化方法就是用顶点颜色来存储每一个顶点到瞄点的距离值，使用描点=顶点位置+顶点和描点距离
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed _VerticalBillboarding;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				// Suppose the center in object space is fixed
				//选择模型空间的原点作为广告牌的描点，绝对位置，商业上一般采样优化方法
				float3 center = float3(0, 0, 0);
				//获取模型空间下的视角位置
				float3 viewer = mul(_World2Object,float4(_WorldSpaceCameraPos, 1));
				//计算模型空间下目标法线方向
				float3 normalDir = viewer - center;
				// 如果 _VerticalBillboarding=1, 意味着法线方向固定为视角方向
				// 如果我们设置为0，意味着向上方向固定为（0，1，0）
				normalDir.y =normalDir.y * _VerticalBillboarding;
				normalDir = normalize(normalDir);//法线归一化
				// 得到粗略的向上方向
				// 如果法线方向和粗略的向上方向平行，那我们后面cross(upDir, normalDir)得到的结果就是0是然后最后得到的updir就是错误的0，于是我们就重新选定一个向上分量
				//我们对法线的y分量进行判断，以得到适合的向上方向,如果normalDir.y>0.999,只要选和normalDir.y垂直的平面中的一个向量就行了，由于float3(0, 0, 1)比较好算，就选这个了
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
				float3 rightDir = normalize(cross(normalDir,upDir));//我个人觉得应该这样，得到的效果是正确的
				upDir = normalize(cross(rightDir,normalDir));
				
				// 得到原始位置相对于描点的偏移量，得到在描点坐标空间下的顶点坐标，这样才能乘以在描点空间下的变换矩阵
				float3 centerOffs = v.vertex.xyz - center;
				//通过正交基变换，得到新的顶点位置（x,y,z)和（right，up，normal）T相乘，然后加上描点坐标偏移，得到模型空间下的变换后的顶点坐标
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
              
				o.pos = mul(UNITY_MATRIX_MVP,float4(localPos, 1));
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				fixed4 c = tex2D (_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/VertexLit"
}

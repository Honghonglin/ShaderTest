// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//适合场景静止，摄像机快速运动
//这是因为我们在计算时只考虑了摄像机的运动，如果物体移动，摄像机静止不产生任何效果
//片元着色器中使用逆矩阵来重建每一个像素在世界空间下的位置，影响性能
Shader "Unity Shaders Book/Chapter 13/Motion Blur With Depth Texture" {
	Properties {
		//Unity中没有提供矩阵类型的属性
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0//控制采样距离
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;//主纹理的纹素大小，使用该变量对深度纹理的采样坐标进行平台差异化处理
		//Unity传递给我们的深度纹理
		sampler2D _CameraDepthTexture;
		//当前帧的视角*投影矩阵
		float4x4 _CurrentViewProjectionInverseMatrix;
		//前一帧的视角*投影矩阵
		float4x4 _PreviousViewProjectionMatrix;
		half _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;//专门对深度纹理采样的纹理坐标
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			//进行平台差异化处理
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
					 
			return o;
		}
		
		fixed4 frag(v2f i) : SV_Target {
			// Get the depth buffer value at this pixel.
			//得到该像素的深度缓冲值
			//SAMPLE_DEPTH_TEXTURE可以处理由于平台差异造成的问题
			//d是由NDC下的坐标映射而来的
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
			// H is the viewport position at this pixel in the range -1 to 1.
			//要构建像素的NDC坐标H，就需要把这个深度值重新映射回NDC，使用原映射的反函数，即d*2-1
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
			// Transform by the view-projection inverse.
			//使用视角*投影矩阵的逆矩阵来变换
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
			// Divide by w to get the world position. 
			//除以w得到世界空间下的深度纹理的像素的坐标
			float4 worldPos = D / D.w;
			
			// Current viewport position 
			//当前帧在NDC下的坐标
			float4 currentPos = H;
			// Use the world position, and transform by the previous view-projection matrix. 
			//使用前一帧的视角*投影矩阵对世界坐标下的纹理坐标进行变换
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			// Convert to nonhomogeneous points [-1,1] by dividing by w.
			//得到在前一帧在NDC下的坐标
			previousPos /= previousPos.w;
			
			// Use this frame's position and last frame's to compute the pixel velocity.
			//计算前一帧和当前帧在屏幕空间下的位置差，得到该像素的速度velocity
			float2 velocity = (currentPos.xy - previousPos.xy)/2.0f;
			
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			uv += velocity * _BlurSize;
			//对邻域像素进行采样，相加
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			//取平均值得到一个模糊效果
			c /= 3;
			
			return fixed4(c.rgb, 1.0);
		}
		
		ENDCG
		
		Pass {      
			ZTest Always Cull Off ZWrite Off
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
	} 
	FallBack Off
}

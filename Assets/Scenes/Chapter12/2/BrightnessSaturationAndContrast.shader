// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 12/Brightness Saturation And Contrast" {
		//仅仅时为了显示在材质面板上，好查看而已，实际上我们是通过脚本来设置这些值
		//所以其实Properties可以删除
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}//对应Grapgics.Blit的第一个参数src
		_Brightness ("Brightness", Float) = 1
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1
	}
	//用于屏幕后处理的pass，实际上实在场景中绘制一个与屏幕同宽同高的四边形片面
	SubShader {
		Pass {  
			//例如如果当前的OnRenderImage（在脚本中）在所有的不透明Pass执行完之后立刻被调用，不关闭深度写入就会影响后面透明渲染的Pass渲染，违反了屏幕后处理
			ZTest Always Cull Off ZWrite Off//关闭深度写入，防止挡住其他在后面被渲染的物体，屏幕后处理Shader标配
			
			CGPROGRAM  
			#pragma vertex vert  
			#pragma fragment frag  
			  
			#include "UnityCG.cginc"  
			  
			sampler2D _MainTex;  
			half _Brightness;
			half _Saturation;
			half _Contrast;
			  
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv: TEXCOORD0;
			};
			  
			v2f vert(appdata_img/*Unity中内置的结构体，只包含了图像处理时必须的顶点坐标和纹理坐标等变量*/ v) {
				v2f o;
				
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				
				o.uv = v.texcoord;
						 
				return o;
			}
		
			fixed4 frag(v2f i) : SV_Target {
				fixed4 renderTex = tex2D(_MainTex, i.uv);  
				  
				// 调节亮度
				fixed3 finalColor = renderTex.rgb * _Brightness;
				
				// 我们计算该像素对应的亮度值
				fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;//每个分量乘以一个特定的属性再相加得到的
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance);//用亮度值创建一个饱和度为0的颜色值 饱和度=三个RGB数值中，最大值与最小值的差值，这个颜色的饱和度为0
				finalColor = lerp(luminanceColor, finalColor, _Saturation);//通过饱和度进行在其和finalColor之间进行插值
				
				// 创建对比度为0的颜色值
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor, finalColor, _Contrast);
				
				return fixed4(finalColor, renderTex.a);  
			}  
			  
			ENDCG
		}  
	}
	
	Fallback Off
}

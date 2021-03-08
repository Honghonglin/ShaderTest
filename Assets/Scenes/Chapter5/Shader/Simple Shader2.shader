Shader "Unity Shaders Book/Chapter 5/Simple Shader2" {
	SubShader{
		Pass {
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			struct a2v {
		//Position语义告诉Unity，用模型空间的顶点坐标填充vertex变量
				float4 vertex : POSITION;
				//NORMAL语义告诉Unity，用模型空间的法线方向填充normal变量
				float3 normal : NORMAL;
				//TEXOORD0语义告诉Unity，用模型的第一套纹理坐标填充texcoord变量
				float4 texcoord : TEXCOORD0;
			};


	//使用一个结构体来定义顶点着色器的输出
	struct v2f {
		//SV_POSITION语义告诉Unity，pos里包含了顶点在裁剪空间中的位置信息
		float4 pos : SV_POSITION;
		//COLOR0语义 可以用于存储颜色信息
		fixed3 color : COLOR0;
		};
//这里SV_POSITION不用写，因为输出并不只是SV_POSITION
		v2f vert(a2v v) {
			//声明输出结构
			v2f o;
		//将顶点坐标从模型空间转换带裁剪空间中
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		//v.normal包含了顶点的法线方向，其分量范围在[-1.0,1.0]
		//下面的代码把分量范围映射到[0.0,1.0]
		//存储到o.color中传递给片元着色器
		o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
		return o;
	}
			//片元着色器中的输入实际上就是把顶点着色器的输出进行插值后得到的结果。
				fixed4 frag(v2f i) : SV_Target{
		//将插值后的i.color显示到屏幕上
		return fixed4(i.color, 1.0);
	}
		ENDCG
		}
	}
}
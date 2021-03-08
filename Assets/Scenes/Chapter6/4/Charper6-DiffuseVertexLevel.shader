//逐定点光照（兰伯特光照模型）  对于细分程度高的模型引用较好 反之不然
//问题例如：背光部分和向光部分的交界处会有锯齿
//改善技术：逐像素光照
Shader "Unity Shaders Book/Chapter 6/Charper6-DiffuseVertextLevel" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1,1,1,1)
	}
	SubShader {
	Pass{
//指定光照模式
//定义正确的LightMode才能得到一些Unity的内置光照变量
		Tags { "LightMode"="ForwardBase" }
		CGPROGRAM
//定义顶点着色器和片元着色器名称
		#pragma vertex vert
		#pragma fragment frag
//使用Unity内置变量要包含一些文件  
#include "Lighting.cginc"
//为了使用Properties中声明的属性 定义匹配属性
fixed4 _Diffuse;
//这样我们就可以得到材质的漫反射属性了[0,]
		
//定义顶点着色器输入结构体
struct a2v{
float4 vertex:POSITION;
float4 normal:NORMAL;//存储顶点法线信息
};
//顶点着色器输出结构体
//片元的输入结构体
struct v2f{
float4 pos:SV_POSITION;
fixed3 color:COLOR;//存储顶点计算的到的光照颜色
};
//实现逐顶点的漫反射光照
v2f vert(a2v v) {
				v2f o;
				//模型空间转化为裁剪空间
				o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
				
				// 得到环境光部分
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// Transform the normal from object space to world space
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)_World2Object/*模型空间到世界空间的逆矩阵*/));
				// Get the light direction in world space  假设只有一个光源且该光源的类型是平行光
				//但如果场景有多个光源并且类型可能是点光源等其他类型，就不能直接用这个
				//worldLight和worldNormal点积在同一坐标系下才有意义
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				// Compute diffuse term
				//通过_LightColor0访问该Pass处理的光源的颜色和强度信息  注意LightMode要定义合适
				//得到最后的漫反射光照结果
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight)/*截取到[0,1]*/);
				
				o.color =ambient + diffuse;
				
				return o;
			}
fixed4 frag(v2f i) : SV_Target {
	return fixed4(i.color, 1.0);//输出颜色
}
		ENDCG
	}
} 
	FallBack "Diffuse"
}

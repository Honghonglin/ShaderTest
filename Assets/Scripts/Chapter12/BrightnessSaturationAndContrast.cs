using UnityEngine;
using System.Collections;

public class BrightnessSaturationAndContrast : PostEffectsBase
{
	//特效shader
	public Shader briSatConShader;
	//我们创建的材质
	private Material briSatConMaterial;
	public Material material
	{
		get
		{
			briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, briSatConMaterial);
			return briSatConMaterial;
		}
	}

	[Range(0.0f, 3.0f)]
	public float brightness = 1.0f;//调节亮度

	[Range(0.0f, 3.0f)]
	public float saturation = 1.0f;//饱和度

	[Range(0.0f, 3.0f)]
	public float contrast = 1.0f;//对比度
	//[ImageEffectOpaque]//添加上可以让OnRenderImage函数在不透明的Pass执行完毕后立刻执行
	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		//检查材质是否可用
		if (material != null)
		{
			material.SetFloat("_Brightness", brightness);
			material.SetFloat("_Saturation", saturation);
			material.SetFloat("_Contrast", contrast);

			Graphics.Blit(src, dest, material);//参数传入处理图像
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}

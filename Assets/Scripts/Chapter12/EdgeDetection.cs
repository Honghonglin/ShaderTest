using UnityEngine;
using System.Collections;

public class EdgeDetection : PostEffectsBase
{

	public Shader edgeDetectShader;//我们指定的Shader
	private Material edgeDetectMaterial = null;
	public Material material
	{
		get
		{
			edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
			return edgeDetectMaterial;
		}
	}

	[Range(0.0f, 1.0f)]
	public float edgesOnly = 0.0f;//边缘线强度  为0时，边缘将会叠加到原渲染图像上，为1时，只显示边缘，不显示原渲染图像

	public Color edgeColor = Color.black;//描边颜色

	public Color backgroundColor = Color.white;//背景颜色

	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (material != null)
		{
			material.SetFloat("_EdgeOnly", edgesOnly);
			material.SetColor("_EdgeColor", edgeColor);
			material.SetColor("_BackgroundColor", backgroundColor);

			Graphics.Blit(src, dest, material);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}

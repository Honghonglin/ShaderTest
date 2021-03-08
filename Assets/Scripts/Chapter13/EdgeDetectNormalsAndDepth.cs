using UnityEngine;
using System.Collections;

public class EdgeDetectNormalsAndDepth : PostEffectsBase
{

	public Shader edgeDetectShader;
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
	public float edgesOnly = 0.0f;//调整边缘强度

	public Color edgeColor = Color.black;//边缘线颜色

	public Color backgroundColor = Color.white;//背景颜色

	public float sampleDistance = 1.0f;//控制深度+法线纹理采样时，使用的采样距离，值越大，描边越宽

	public float sensitivityDepth = 1.0f;//对深度进行边缘检测的灵敏度，影响当领域的深度值相差多少时，被认为存在一条边界

	public float sensitivityNormals = 1.0f;//对法线进行边缘检测的灵敏度

	void OnEnable()
	{
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
	}

	[ImageEffectOpaque]//我们只希望对不透明物体描边，所以我们让渲染在不透明物体被渲染后调用
	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (material != null)
		{
			material.SetFloat("_EdgeOnly", edgesOnly);
			material.SetColor("_EdgeColor", edgeColor);
			material.SetColor("_BackgroundColor", backgroundColor);
			material.SetFloat("_SampleDistance", sampleDistance);
			material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));

			Graphics.Blit(src, dest, material);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}

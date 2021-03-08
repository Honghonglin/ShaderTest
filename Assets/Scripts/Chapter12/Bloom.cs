using UnityEngine;
using System.Collections;

public class Bloom : PostEffectsBase
{

	public Shader bloomShader;
	private Material bloomMaterial = null;
	public Material material
	{
		get
		{
			bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
			return bloomMaterial;
		}
	}

	// Blur iterations - larger number means more blur.
	[Range(0, 4)]
	public int iterations = 3;

	// Blur spread for each iteration - larger value means more blur
	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;

	[Range(1, 8)]
	public int downSample = 2;
	//大多数情况下，图像的亮度值不会超过1，但是如果我们开启HDR，硬件会运行我们把颜色存储在一个更高精度范围的缓冲中
	//此时像素的亮度值可能会超过1。
	[Range(0.0f, 4.0f)]
	public float luminanceThreshold = 0.6f;//来控制提取较亮区域时使用的阈值

	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (material != null)
		{
			material.SetFloat("_LuminanceThreshold", luminanceThreshold);

			int rtW = src.width / downSample;
			int rtH = src.height / downSample;

			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			buffer0.filterMode = FilterMode.Bilinear;

			Graphics.Blit(src, buffer0, material, 0);//我们使用Shader中的第一个Pass提取图像中的较亮区域，提取得到的较亮区域将存储在buffer0中
			//和高斯模糊迭代处理一样
			for (int i = 0; i < iterations; i++)
			{
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// Render the vertical pass
				Graphics.Blit(buffer0, buffer1, material, 1);

				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// Render the horizontal pass
				Graphics.Blit(buffer0, buffer1, material, 2);

				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			material.SetTexture("_Bloom", buffer0);
			Graphics.Blit(src, dest, material, 3);///使用第四个Pass进行较亮区域模糊后的纹理和原图的混合

			RenderTexture.ReleaseTemporary(buffer0);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}

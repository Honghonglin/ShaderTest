using UnityEngine;
using System.Collections;

public class GaussianBlur : PostEffectsBase
{

	public Shader gaussianBlurShader;
	private Material gaussianBlurMaterial = null;

	public Material material
	{
		get
		{
			gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
			return gaussianBlurMaterial;
		}
	}

	// Blur iterations - larger number means more blur.
	[Range(0, 4)]
	public int iterations = 3;//高斯模糊迭代次数

	// Blur spread for each iteration - larger value means more blur
	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;//模糊范围

	[Range(1, 8)]
	public int downSample = 2;//缩放系数参数  越大需要处理的像素数越小，同时能够进一步提高模糊程度，但过大的downSample可能会使图像像素化
							  //版本一：
	/// 1st edition: just apply blur
	//	void OnRenderImage(RenderTexture src, RenderTexture dest) {
	//		if (material != null) {
	//			int rtW = src.width;
	//			int rtH = src.height;
	//使用RenderTexture.GetTemporary函数分配了一块与屏幕图像大小相同的缓冲区
	//这是因为高斯模糊需要调用两个Pass，我们需要使用一块中间缓存来存储第一个Pass执行完毕后得到的模糊结果
	//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
	//
	//			// Render the vertical pass
	//使用Shader中的第一个Pass（即竖直方向的一维高斯核）对src进行滤波，并将结果存储在buffer中
	//			Graphics.Blit(src, buffer, material, 0);
	//			// Render the horizontal pass
	//使用Shader中的第二个Pass（即水平方向的一维高斯核）对src进行滤波，并将结果存储在dest（最终屏幕图像）中
	//			Graphics.Blit(buffer, dest, material, 1);
	//			释放之前分配的缓存
	//			RenderTexture.ReleaseTemporary(buffer);
	//		} else {
	//			Graphics.Blit(src, dest);
	//		}
	//	} 
	//版本二：使用缩放对图像进行降采样，从而减少需要处理的像素个数，提高性能
	/// 2nd edition: scale the render texture
	//	void OnRenderImage (RenderTexture src, RenderTexture dest) {
	//		if (material != null) {
	//			int rtW = src.width/downSample;//使用小于原屏幕分辨率的尺寸
	//			int rtH = src.height/downSample;
	//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
	//			buffer.filterMode = FilterMode.Bilinear;//将该临时渲染纹理的滤波模式设置为双线性，理解：https://www.cnblogs.com/cxrs/archive/2009/10/18/justaprogramer.html
	//
	//			// Render the vertical pass
	//			Graphics.Blit(src, buffer, material, 0);
	//			// Render the horizontal pass
	//			Graphics.Blit(buffer, dest, material, 1);
	//
	//			RenderTexture.ReleaseTemporary(buffer);
	//		} else {
	//			Graphics.Blit(src, dest);
	//		}
	//	}
	//版本三：把高斯模糊的迭代次数考虑进去
	/// 3rd edition: use iterations for larger blur
	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (material != null)
		{
			int rtW = src.width / downSample;
			int rtH = src.height / downSample;

			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			buffer0.filterMode = FilterMode.Bilinear;

			Graphics.Blit(src, buffer0);//将src缩放后的图像存储到buffer0

			for (int i = 0; i < iterations; i++)
			{
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// Render the vertical pass
				Graphics.Blit(buffer0, buffer1, material, 0);
				//把buffer0释放
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;//把buffer0指向buffer1指向的空间
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);//重新分配buffer1指向空间

				// Render the horizontal pass
				Graphics.Blit(buffer0, buffer1, material, 1);

				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			Graphics.Blit(buffer0, dest);//最后的buffer0就是目标纹理
			RenderTexture.ReleaseTemporary(buffer0);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}

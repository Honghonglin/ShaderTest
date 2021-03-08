using UnityEngine;
using System.Collections;

public class MotionBlur : PostEffectsBase
{

	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;

	public Material material
	{
		get
		{
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}
	}
	//为了防止拖尾效果完全替代当前帧的渲染，我们定义范围为0-0.9
	[Range(0.0f, 0.9f)]
	public float blurAmount = 0.5f;//运动模糊在混合图像时使用的模糊参数，越大，物体拖尾效果就越明显

	private RenderTexture accumulationTexture;//模糊运动的纹理（前一帧
	//在禁用时，销魂模糊运动纹理，我们希望下一次开始应用运动模糊时重新叠加图像
	void OnDisable()
	{
		DestroyImmediate(accumulationTexture);
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (material != null)
		{
			// Create the accumulation texture
			if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height)
			{
				DestroyImmediate(accumulationTexture);
				accumulationTexture = new RenderTexture(src.width, src.height, 0);
				accumulationTexture.hideFlags = HideFlags.HideAndDontSave;//不会显示在hirearchy也不会被保存在场景，需要主动销毁
				Graphics.Blit(src, accumulationTexture);//当前帧初始化为accumulationTexture
			}

			// We are accumulating motion over frames without clear/discard
			// by design, so silence any performance warnings from Unity
			//恢复操作发生在渲染到纹理而该纹理有没有被提前清空或销毁的情况下
			//因为accumulationTexture保存了我们之前的混合结果，所有不需要提前清空
			accumulationTexture.MarkRestoreExpected();//对渲染纹理进行恢复操作

			material.SetFloat("_BlurAmount", 1.0f - blurAmount);
			//将src中进行material操作叠加入accumulationTexture中
			Graphics.Blit(src, accumulationTexture, material);
			Graphics.Blit(accumulationTexture, dest);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}

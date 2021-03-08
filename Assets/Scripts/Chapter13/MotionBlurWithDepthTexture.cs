using UnityEngine;
using System.Collections;

public class MotionBlurWithDepthTexture : PostEffectsBase
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
	//由于我们需要得到摄像机的视角和投影矩阵，我们需要定义一个Camera变量
	private Camera myCamera;
	public Camera Camera
	{
		get
		{
			if (myCamera == null)
			{
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}

	[Range(0.0f, 1.0f)]
	public float blurSize = 0.5f;//

	private Matrix4x4 previousViewProjectionMatrix;//保存上一帧摄像机的视角投影矩阵

	void OnEnable()
	{
		//要得到摄像机的深度纹理，就更改depthTextureMode设置
		Camera.depthTextureMode |= DepthTextureMode.Depth;
		//camera.worldToCameraMatri为摄像机的视角矩阵
		// camera.projectionMatri为摄像机的投影矩阵
		//这里就是视角*投影矩阵
		//为了一开始不出错，先给个初值
		previousViewProjectionMatrix = Camera.projectionMatrix * Camera.worldToCameraMatrix;
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (material != null)
		{
			material.SetFloat("_BlurSize", blurSize);

			material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
			Matrix4x4 currentViewProjectionMatrix = Camera.projectionMatrix * Camera.worldToCameraMatrix;
			//视角*投影的逆矩阵
			Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
			material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
			previousViewProjectionMatrix = currentViewProjectionMatrix;//存储当前帧的视角*投影矩阵

			Graphics.Blit(src, dest, material);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}

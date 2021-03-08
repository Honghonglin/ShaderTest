﻿using UnityEngine;
using System.Collections;

public class FogWithDepthTexture : PostEffectsBase
{

	public Shader fogShader;
	private Material fogMaterial = null;

	public Material material
	{
		get
		{
			fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}
	}

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

	private Transform myCameraTransform;
	public Transform cameraTransform
	{
		get
		{
			if (myCameraTransform == null)
			{
				myCameraTransform = Camera.transform;
			}

			return myCameraTransform;
		}
	}

	[Range(0.0f, 3.0f)]
	public float fogDensity = 1.0f;//控制雾的浓度

	public Color fogColor = Color.white;//控制雾的颜色
	//我们使用的雾效是基于高度的
	public float fogStart = 0.0f;//雾效的起始高度
	public float fogEnd = 2.0f;//雾效的终止高度

	void OnEnable()
	{
		Camera.depthTextureMode |= DepthTextureMode.Depth;//设置摄像机状态，以获取深度纹理
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if (material != null)
		{
			#region 套用公式,详情见书
			//存储四个角对应的向量
            Matrix4x4 frustumCorners = Matrix4x4.identity;

			float fov = Camera.fieldOfView;
			float near = Camera.nearClipPlane;
			float aspect = Camera.aspect;

			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toRight = cameraTransform.right * halfHeight * aspect;
			Vector3 toTop = cameraTransform.up * halfHeight;

			Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
			float scale = topLeft.magnitude / near;

			topLeft.Normalize();
			topLeft *= scale;

			Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
			topRight.Normalize();
			topRight *= scale;

			Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
			bottomLeft.Normalize();
			bottomLeft *= scale;

			Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= scale;
			//顺序很重要，这决定我们再顶点着色器中使用哪一行作为该点的待插值向量
			frustumCorners.SetRow(0, bottomLeft);//存储到第一行 左下
			frustumCorners.SetRow(1, bottomRight);//右下
			frustumCorners.SetRow(2, topRight);//右上
			frustumCorners.SetRow(3, topLeft);//左上
            #endregion
            material.SetMatrix("_FrustumCornersRay", frustumCorners);

			material.SetFloat("_FogDensity", fogDensity);
			material.SetColor("_FogColor", fogColor);
			material.SetFloat("_FogStart", fogStart);
			material.SetFloat("_FogEnd", fogEnd);

			Graphics.Blit(src, dest, material);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}
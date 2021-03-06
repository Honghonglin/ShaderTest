using UnityEngine;
using System.Collections;

public class FogWithNoise : PostEffectsBase {

	public Shader fogShader;
	private Material fogMaterial = null;

	public Material material {  
		get {
			fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}  
	}
	
	private Camera myCamera;
	public Camera Camera {
		get {
			if (myCamera == null) {
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}

	private Transform myCameraTransform;
	public Transform CameraTransform {
		get {
			if (myCameraTransform == null) {
				myCameraTransform = Camera.transform;
			}
			
			return myCameraTransform;
		}
	}

	[Range(0.1f, 3.0f)]
	public float fogDensity = 1.0f;//控制雾的浓度

	public Color fogColor = Color.white;//控制雾的颜色
	//我们使用的雾效shader的模拟函数时基于高度的，所以
	public float fogStart = 0.0f;//控制雾效的起始高度
	public float fogEnd = 2.0f;//控制雾效的终止高度

	public Texture noiseTexture;//噪声纹理

	[Range(-0.5f, 0.5f)]
	public float fogXSpeed = 0.1f;//噪声纹理在X方向上的移动速度

	[Range(-0.5f, 0.5f)]
	public float fogYSpeed = 0.1f;//噪声纹理在Y方向上的移动速度

	[Range(0.0f, 3.0f)]
	public float noiseAmount = 1.0f;//控制噪声程度，当为0时，表示不应用任何噪声，即得到一个均匀的基于高度的全局雾效

	void OnEnable() {
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
	}
		
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			Matrix4x4 frustumCorners = Matrix4x4.identity;
			//见13.3节
			float fov = Camera.fieldOfView;
			float near = Camera.nearClipPlane;
			float aspect = Camera.aspect;
			
			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toRight = CameraTransform.right * halfHeight * aspect;
			Vector3 toTop = CameraTransform.up * halfHeight;
			
			Vector3 topLeft = CameraTransform.forward * near + toTop - toRight;
			float scale = topLeft.magnitude / near;
			
			topLeft.Normalize();
			topLeft *= scale;
			
			Vector3 topRight = CameraTransform.forward * near + toRight + toTop;
			topRight.Normalize();
			topRight *= scale;
			
			Vector3 bottomLeft = CameraTransform.forward * near - toTop - toRight;
			bottomLeft.Normalize();
			bottomLeft *= scale;
			
			Vector3 bottomRight = CameraTransform.forward * near + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= scale;
			
			frustumCorners.SetRow(0, bottomLeft);
			frustumCorners.SetRow(1, bottomRight);
			frustumCorners.SetRow(2, topRight);
			frustumCorners.SetRow(3, topLeft);
			
			material.SetMatrix("_FrustumCornersRay", frustumCorners);

			material.SetFloat("_FogDensity", fogDensity);
			material.SetColor("_FogColor", fogColor);
			material.SetFloat("_FogStart", fogStart);
			material.SetFloat("_FogEnd", fogEnd);

			material.SetTexture("_NoiseTex", noiseTexture);
			material.SetFloat("_FogXSpeed", fogXSpeed);
			material.SetFloat("_FogYSpeed", fogYSpeed);
			material.SetFloat("_NoiseAmount", noiseAmount);

			Graphics.Blit (src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}

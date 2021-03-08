using UnityEngine;
using System.Collections;
using System.Collections.Generic;
//在编辑器下可也运行
[ExecuteInEditMode]
public class ProceduralTextureGeneration : MonoBehaviour
{
	public Material material = null;
	#region 材质属性
	[SerializeField, SetProperty("textureWidth")/*设置属性为textureWidth*/]
	private int m_textureWidth = 512;
	public int textureWidth//纹理大小 通常为2的整数幂
	{
		get
		{
			return m_textureWidth;
		}
		set
		{
			m_textureWidth = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("backgroundColor")]
	private Color m_backgroundColor = Color.white;
	public Color backgroundColor//纹理的背景颜色
	{
		get
		{
			return m_backgroundColor;
		}
		set
		{
			m_backgroundColor = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("circleColor")]
	private Color m_circleColor = Color.blue;
	public Color circleColor//圆点颜色
	{
		get
		{
			return m_circleColor;
		}
		set
		{
			m_circleColor = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("blurFactor")]
	private float m_blurFactor = 2.0f;
	public float blurFactor//模糊因子
	{
		get
		{
			return m_blurFactor;
		}
		set
		{
			m_blurFactor = value;
			_UpdateMaterial();
		}
	}
	#endregion

	private Texture2D m_generatedTexture = null;//保存生成的程序纹理

	// Use this for initialization
	void Start()
	{
		if (material == null)
		{
			Renderer renderer = gameObject.GetComponent<Renderer>();
			if (renderer == null)
			{
				Debug.LogWarning("Cannot find a renderer.");
				return;
			}

			material = renderer.sharedMaterial;
		}

		_UpdateMaterial();
	}

	private void _UpdateMaterial()
	{
		if (material != null)
		{
			m_generatedTexture = _GenerateProceduralTexture();//生成一张程序纹理
			material.SetTexture("_MainTex", m_generatedTexture);//设置纹理给material的_MainTex
		}
	}

	//mixFactor =0 则返回color0    为1返回color1
	private Color _MixColor(Color color0, Color color1, float mixFactor)
	{
		Color mixColor = Color.white;
		mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
		mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
		mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
		mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
		return mixColor;
	}

	private Texture2D _GenerateProceduralTexture()
	{
		Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

		// ⚪和⚪之间的距离
		float circleInterval = textureWidth / 4.0f;
		// 定义圆的半径
		float radius = textureWidth / 10.0f;
		// T模糊系数
		float edgeBlur = 1.0f / blurFactor;

		for (int w = 0; w < textureWidth; w++)
		{
			for (int h = 0; h < textureWidth; h++)
			{
				// Initalize the pixel with background color
				Color pixel = backgroundColor;

				// Draw nine circles one by one
				for (int i = 0; i < 3; i++)
				{
					for (int j = 0; j < 3; j++)
					{
						//计算圆心位置
						Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));

						// 计算当前像素和圆圈的距离
						float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;

						// 模糊圆的边界
						// Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur)  比较难理解  如果这个像素里圆边缘很远 如果在外的话那么dist * edgeBlur很大，返回值为1  那么color为前一个pixel
						//如果在内 返回0  那么color为circleColor
						//如果离边缘很近  那么 dist * edgeBlur会属于0-1  而edgeBlur会控制这个距离，越小的话，模糊范围越大
						//离边缘很近的话，那么返回的颜色会更偏向circleColor
						//当在圆圈上时，那么颜色就是圆圈颜色
						Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));

						//与之前得到的颜色进行混合
						pixel = _MixColor(pixel, color, color.a);
					}
				}

				proceduralTexture.SetPixel(w, h, pixel);
			}
		}

		proceduralTexture.Apply();//保存程序纹理

		return proceduralTexture;
	}
}

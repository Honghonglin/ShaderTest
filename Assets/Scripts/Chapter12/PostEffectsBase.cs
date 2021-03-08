using UnityEngine;
using System.Collections;
/// <summary>
///一个用来屏幕后处理效果的基类，在实现各种屏幕特效时，我们只需要继承自该基类（处理检测是否满足屏幕后处理条件
///需要绑定在某个摄像机上
/// </summary>
[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostEffectsBase : MonoBehaviour
{

	// Called when start
	//一些屏幕特性可能需要更多的设置，例如一些默认值等，可以重载Start，CheckResources或CheckSupport函数
	protected void CheckResources()
	{
		bool isSupported = CheckSupport();//检查各种资源和条件是否满足

		if (isSupported == false)
		{
			NotSupported();
		}
	}
	
	// Called in CheckResources to check support on this platform
	protected bool CheckSupport()
	{
		if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
		{
			Debug.LogWarning("This platform does not support image effects or render textures.");
			return false;
		}

		return true;
	}

	// Called when the platform doesn't support this effect
	protected void NotSupported()
	{
		enabled = false;
	}

	protected void Start()
	{
		CheckResources();
	}

	// Called when need to create the material used by this effect
	//由于每个屏幕处理效果通常都需要指定一个Shader来创建一个用于处理渲染纹理的材质，因此基类中也提供了这样的方法
	//第一个参数指定了该特效需要使用的Shader，第二个参数则是用于后期处理的材质
	protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
	{
		if (shader == null)
		{
			return null;
		}
		//检查Shader可用性
		//后期处理shder和特效需要的shader一样就直接返回
		if (shader.isSupported && material && material.shader == shader)
			return material;

		if (!shader.isSupported)
		{
			return null;
		}
		else
		{
			//创建一个为Shader后期处理材质
			material = new Material(shader);
			material.hideFlags = HideFlags.DontSave;//不随着场景变化而销毁
			if (material)
				return material;
			else
				return null;
		}
	}
}

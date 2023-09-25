using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/CRTPostProcess")]
public sealed class CRTPostProcess : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0,0,1);
    public ClampedFloatParameter curve = new ClampedFloatParameter(0,0,10);
    public ClampedFloatParameter frequency = new ClampedFloatParameter(1,0,10);
    public ClampedFloatParameter offset = new ClampedFloatParameter(1,0,1);
    public ClampedFloatParameter scale = new ClampedFloatParameter(1,0,1);
    public ClampedFloatParameter width = new ClampedFloatParameter(0,0,100);
    public ClampedFloatParameter saturation = new ClampedFloatParameter(1,-2,2);
    public ClampedFloatParameter contrast = new ClampedFloatParameter(0,-1,1);

    public ClampedFloatParameter dStep = new ClampedFloatParameter(0,0,64);
    public ClampedFloatParameter dSlope = new ClampedFloatParameter(0,0,1);
    public ClampedFloatParameter dSpeed = new ClampedFloatParameter(0,-1,1);

    Material mat;

    public bool IsActive() => mat != null || intensity.value == 0;
   
    public override CustomPostProcessInjectionPoint injectionPoint 
        => CustomPostProcessInjectionPoint.AfterPostProcess;
    public override void Render(CommandBuffer cmd, HDCamera camera,
        RTHandle source, RTHandle destination)
    {
        if (mat == null) return;

        mat.SetFloat("_Intensity", intensity.value);
        mat.SetFloat("_Curve", curve.max - curve.value);
        mat.SetFloat("_Frequency", frequency.value);
        mat.SetFloat("_Offset", offset.value);
        mat.SetFloat("_Scale", scale.value);
        mat.SetFloat("_Width", width.value);
        mat.SetFloat("_Saturation", saturation.value);
        mat.SetFloat("_Contrast", contrast.value);
        mat.SetFloat("_DistortionStep", dStep.value);
        mat.SetFloat("_DistortionSlope", dSlope.value);
        mat.SetFloat("_DistortionSpeed", dSpeed.value);
        cmd.Blit(source, destination, mat, 0);
    }

    const string kShaderName = "Hidden/Shader/CRTPostProcess";

    public override void Setup()
    {
        if (Shader.Find(kShaderName) != null)
            mat = new Material(Shader.Find(kShaderName));
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume CRTPostProcess is unable to load.");

    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(mat);
    }
}

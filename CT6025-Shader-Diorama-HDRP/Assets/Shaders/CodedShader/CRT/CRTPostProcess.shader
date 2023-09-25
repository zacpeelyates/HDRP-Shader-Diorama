Shader "Hidden/Shader/CRTPostProcess"
{
    Properties
    {
        // This property is necessary to make the CommandBuffer.Blit bind the source texture to _MainTex
        _MainTex("Main Texture", 2DArray) = "grey" {}
    }

    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"

    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    Varyings Vert(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
        return output;
    }

    // List of properties to control your post process effect
    float _Curve;
    float _Frequency;
    float _Offset;
    float _Scale;
    float _Intensity;
    float _Width;
    float _Saturation;
    float _Contrast;
    float _DistortionStep; 
    float _DistortionSpeed;
    float _DistortionSlope;

    TEXTURE2D_X(_MainTex);

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        // Note that if HDUtils.DrawFullScreen is used to render the post process, use ClampAndScaleUVForBilinearPostProcessTexture(input.texcoord.xy) to get the correct UVs
        float3 col = SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler, input.texcoord).rgb; //default color
        if(_Intensity == 0) return float4(col,1); //early out

        //curve
        float2 uv = input.texcoord * 2 - 1; //remap
        float2 offset = uv.yx / _Curve; //distort
        uv += uv * pow(offset,2); //offset
        uv = uv * 0.5 + 0.5; //recentre

        float2 uv2 = uv * 2 - 1; //Remap + store for vignette
        
        //distortion
        float step = _DistortionStep * 1/_ScreenParams.y;
        float percent = frac(_Time.w * _DistortionSpeed);
        float2 center = float2(0.5,1-percent);
        float thresh = _DistortionSlope * (uv.x - center.x) + center.y;
        uv.x += step * max(sign(uv.y - thresh), 0) - step * percent;

        //vignette   
        float2 v = _Width / _ScreenParams.xy;
        v = saturate(smoothstep(0,v,1-abs(uv2)));

        //Sample
        col = SAMPLE_TEXTURE2D_X(_MainTex, s_linear_clamp_sampler, uv).rgb; 
        

        //color range
        float average = (col.r + col.g + col.b)/3;
        float3 a3 = float3(average,average,average); 
        col = lerp(a3,col,_Saturation);

        //contrast
        float mid = pow(0.5,2.2);
        col = (col - mid) * (1 + _Contrast) + mid;

       //scanlines
        col.rb *= (cos(input.texcoord.y * _ScreenParams.y * _Frequency) + _Offset) * _Scale * 0.9 + _Offset; 
        col.g  *= (sin(input.texcoord.y * _ScreenParams.y * _Frequency) + _Offset) * _Scale + _Offset;

        return float4 ((col * v.x * v.y) ,1);
    }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }
        Pass
        {
            Name "CRTPostProcess"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment CustomPostProcess
                #pragma vertex Vert
            ENDHLSL
        }
    }
    Fallback Off
}

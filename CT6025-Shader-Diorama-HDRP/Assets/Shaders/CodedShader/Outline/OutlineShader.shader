Shader "Custom/OutlineShader"
{
        Properties
        {
             _OutlineColor("Outline Color", color) = (0,0,0,0)
             _OutlineThickness("OutlineThickness",Range(0.01,0.1)) = 0.01
             _Offset("Offset",vector) = (0,0,0,0)
        }
    SubShader
    {

        Pass //outline pass
        {

            Tags
            {
                "RenderType" = "Opaque"
            }
            Cull Front


            CGPROGRAM

            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag
            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            float _OutlineThickness;
            float4 _Offset;

            v2f vert(appdata v)
            {
                v2f o; 
                float l = _OutlineThickness + 1;
                float4x4 outlineM = float4x4(              
                    l, 0, 0, 0,
                    0, l, 0, 0,
                    0, 0, l, 0,
                    0, 0, 0, l);
                
                float4 pos = mul(outlineM, v.vertex + _Offset);
                o.vertex = UnityObjectToClipPos(pos);
                return o;
            }

            float4 _OutlineColor;

            fixed4 frag(v2f i) : SV_TARGET 
            {
                return _OutlineColor;
            }

            ENDCG

        }
       
    }
}

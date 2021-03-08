Shader "Unity Shaders Book/Chapter 5/ Simple Shader1"{
SubShader{
Pass{
CGPROGRAM

#program vertext vert
#program fragment frag

struct v2f{
float4 pos:SV_POSITION;
float3 color0:COLOR0;
float4 color1:COLOR1;
half value0:TEXCOORD0;
float2 value1:TEXCOORD1;
}

Float4 vert(float4 v:POSITION) :SV_POSITION{
Return mul(UNITY_MATRIX_MVP,v);
}
Fixed4 frag() : SV_Target{
Return fixes4(1.0,1.0,1.0,1.0);
}
ENDCG
}
}
}
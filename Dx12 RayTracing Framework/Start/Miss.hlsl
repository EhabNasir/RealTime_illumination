#include "Common.hlsl"

[shader("miss")] void Miss(inout HitInfo payload) 
{ 
    //float3 rayDir = WorldRayOrigin();
    
    //payload.colorAndDistance = float4((rayDir.g + 1.0f) * 0.5f, 0.0f, (rayDir.b + 1.0f) * 0.5f, 1);
    
    //Get current pixel y pos and total height
    uint2 launchIndex = DispatchRaysIndex().xy;
    float2 dims = float2(DispatchRaysDimensions().xy);
    
    //Normalise y to 0-1 range
    float gradientValue = launchIndex.y / dims.y;
    
    payload.colorAndDistance = float4(0, 0, gradientValue, 1);
}

[shader("miss")]
void ShadowMiss(inout ShadowHitInfo payload)
{
    payload.isHit = false;
}
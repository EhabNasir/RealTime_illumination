#include "Common.hlsl"

[shader("miss")] void Miss(inout HitInfo payload : SV_RayPayload) 
{ 
    float3 rayDir = WorldRayOrigin();
    
    payload.colorAndDistance = float4((rayDir.g + 1.0f) * 0.5f, 0.0f, (rayDir.b + 1.0f) * 0.5f, 1);
}
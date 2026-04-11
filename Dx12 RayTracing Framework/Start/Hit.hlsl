#include "Common.hlsl"

#define MAX_RECUSION_DEPTH 2

struct STriVertex
{ // IMPORTANT - the c++ version of this is 'Vertex' found in the common.h file
    float3 vertex;
    float4 normal;
    float2 texCoord;
};

struct Ray
{
    float3 origin;
    float3 direction;
};

StructuredBuffer<STriVertex> BTriVertex : register(t0);
StructuredBuffer<int> indices : register(t1);

cbuffer ColourParams : register(b0)
{
    float4 colourPlane;
    float4 colourDonut;
}

RaytracingAccelerationStructure SceneBVH : register(t2);

float3 HitWorldPosition()
{
    return WorldRayOrigin() + RayTCurrent() * WorldRayDirection();
}

float3 HitAttribute(float3 vertexAttribute[3], Attributes attr)
{
    float3 barycentrics = float3(
        1.0f - attr.bary.x - attr.bary.y,
        attr.bary.x,
        attr.bary.y);
        
    return vertexAttribute[0] * barycentrics.x
         + vertexAttribute[1] * barycentrics.y
         + vertexAttribute[2] * barycentrics.z;
}

// Also add a float2 version for texture coordinates later
float2 HitAttribute2(float2 vertexAttribute[3], Attributes attr)
{
    float3 barycentrics = float3(
        1.0f - attr.bary.x - attr.bary.y,
        attr.bary.x,
        attr.bary.y);
        
    return vertexAttribute[0] * barycentrics.x
         + vertexAttribute[1] * barycentrics.y
         + vertexAttribute[2] * barycentrics.z;
}

float4 TraceRadianceRay(in Ray ray, in uint currentRayRecursionDepth)
{
    if (currentRayRecursionDepth >= MAX_RECUSION_DEPTH)
    {
        return float4(0, 0, 0, 0);
    }

    RayDesc rayDesc;
    rayDesc.Origin = ray.origin;
    rayDesc.Direction = ray.direction;
    rayDesc.TMin = 0.001f;
    rayDesc.TMax = 100000.0f;

    HitInfo reflectionPayload;
    reflectionPayload.colorAndDistance = float4(0, 0, 0, 0);
    reflectionPayload.recursionDepth = currentRayRecursionDepth + 1;

    TraceRay(
        SceneBVH,
        RAY_FLAG_NONE,
        0xFF,
        0,
        0,
        0,
        rayDesc,
        reflectionPayload
    );

    return reflectionPayload.colorAndDistance;
}

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, Attributes attrib)
{
    uint vertId = 3 * PrimitiveIndex();
    
    STriVertex A = BTriVertex[indices[vertId + 0]];
    STriVertex B = BTriVertex[indices[vertId + 1]];
    STriVertex C = BTriVertex[indices[vertId + 2]];

    float3 vertexNormals[3] = { A.normal.xyz, B.normal.xyz, C.normal.xyz };
    float3 triangleNormal = HitAttribute(vertexNormals, attrib);
    float3 worldNormal = normalize(mul(triangleNormal, (float3x3) ObjectToWorld4x3()));
    float3 worldPosition = HitWorldPosition();

    // Per object colour
    float3 objectColour;
    if (InstanceID() == 0)
        objectColour = colourDonut.rgb;
    else
        objectColour = float3(0, 0, 1);

    // Lighting
    float3 lightPosition = float3(0, 5, 0);
    float3 lightDir = normalize(lightPosition - worldPosition);
    float diffuse = max(dot(worldNormal, lightDir), 0.0f);
    float ambient = 0.1f;

    float3 viewDir = normalize(WorldRayOrigin() - worldPosition);
    float3 reflectDir = reflect(-lightDir, worldNormal);
    float specular = pow(max(dot(viewDir, reflectDir), 0.0f), 32.0f);

    // Shadow ray - only on first pass to avoid expensive recursion
    float shadowFactor = 1.0f;
    if (payload.recursionDepth == 0)
    {
        RayDesc shadowRay;
        shadowRay.Origin = worldPosition;
        shadowRay.Direction = lightDir;
        shadowRay.TMin = 0.001f;
        shadowRay.TMax = length(lightPosition - worldPosition);

        ShadowHitInfo shadowPayload;
        shadowPayload.isHit = false;

        TraceRay(SceneBVH, RAY_FLAG_NONE, 0xFF,
            1, 0, 1, // shadow hit offset=1, shadow miss index=1
            shadowRay, shadowPayload);

        if (shadowPayload.isHit)
            shadowFactor = 0.2f;
    }

    // Reflection ray
    Ray reflectionRay;
    reflectionRay.origin = worldPosition;
    reflectionRay.direction = reflect(WorldRayDirection(), worldNormal);

    float4 reflectionColour = TraceRadianceRay(reflectionRay, payload.recursionDepth);

    // Combine everything
    float3 finalColour = objectColour * (ambient + diffuse * shadowFactor + specular)
                       + reflectionColour.rgb * 0.3f; // 0.3 = reflection strength

    payload.colorAndDistance = float4(finalColour, RayTCurrent());
}

[shader("closesthit")]
void PlaneClosestHit(inout HitInfo payload, Attributes attrib)
{
    uint vertId = 3 * PrimitiveIndex();
    
    STriVertex A = BTriVertex[indices[vertId + 0]];
    STriVertex B = BTriVertex[indices[vertId + 1]];
    STriVertex C = BTriVertex[indices[vertId + 2]];

    float3 vertexNormals[3] = { A.normal.xyz, B.normal.xyz, C.normal.xyz };
    float3 triangleNormal = HitAttribute(vertexNormals, attrib);
    float3 worldNormal = normalize(mul(triangleNormal, (float3x3) ObjectToWorld4x3()));
    float3 worldPosition = HitWorldPosition();

    float3 lightPosition = float3(0, 5, 0);
    float3 lightDir = normalize(lightPosition - worldPosition);
    float diffuse = max(dot(worldNormal, lightDir), 0.0f);
    float ambient = 0.1f;

    // Shadow ray
    float shadowFactor = 1.0f;
    if (payload.recursionDepth == 0)
    {
        RayDesc shadowRay;
        shadowRay.Origin = worldPosition;
        shadowRay.Direction = lightDir;
        shadowRay.TMin = 0.001f;
        shadowRay.TMax = length(lightPosition - worldPosition);

        ShadowHitInfo shadowPayload;
        shadowPayload.isHit = false;

        TraceRay(SceneBVH, RAY_FLAG_NONE, 0xFF,
            1, 0, 1,
            shadowRay, shadowPayload);

        if (shadowPayload.isHit)
            shadowFactor = 0.2f;
    }

    // Reflection ray
    Ray reflectionRay;
    reflectionRay.origin = worldPosition;
    reflectionRay.direction = reflect(WorldRayDirection(), worldNormal);

    float4 reflectionColour = TraceRadianceRay(reflectionRay, payload.recursionDepth);

    // Combine
    float3 finalColour = colourPlane.rgb * (ambient + diffuse * shadowFactor)
                       + reflectionColour.rgb * 0.5f; // plane is more reflective

    payload.colorAndDistance = float4(finalColour, RayTCurrent());
}

[shader("closesthit")]
void ShadowClosestHit(inout ShadowHitInfo payload, Attributes attrib)
{
    payload.isHit = true;
}
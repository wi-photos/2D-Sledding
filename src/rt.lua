-- Author: C. Cords (https://github.com/clemapfel/)
-- licensed MIT, see https://opensource.org/license/mit/

rt = {}
rt.snow_effect_shader_source = [[
#pragma language glsl3

// GPU-side random generator
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float random(vec2 v)
{
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
    0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
    -0.577350269189626,  // -1.0 + 2.0 * C.x
    0.024390243902439); // 1.0 / 41.0

    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float random(float x)
{
    return random(vec2(x, x));
}

// triangle wave with same period and amplitude as sine
float triangle_wave(float x)
{
    float pi = 2 * (355 / 113); // 2 * pi
    return 4 * abs((x / pi) + 0.25 - floor((x / pi) + 0.75)) - 1;
}

#ifdef VERTEX // vertex shader

uniform int _instance_count;
uniform float _time;

flat varying int _instance_id;

vec4 position(mat4 transform, vec4 vertex_position)
{
    _instance_id = love_InstanceID;

    float speed = 70;       // fall-speed of snow
    float amplitude = 8;    // maximum left-right movement of snowflake
    float frequency = 5;    // speed of left-right movement

    float wind_offset = (sin(_time / 20) + triangle_wave(_time / 20)) * 750 / 2;
    // shift all snowflakes slightly over time, as if wind was blowing them to one side

    // randomize speed for each snowflake based on instance id
    speed += random(vec2(_instance_id * 2 * _instance_count)) * 50;

    // scale to whole screen
    vertex_position.xy *= love_ScreenSize.xy;

    // snowflake movement
    vertex_position.y += _time * speed;
    vertex_position.x += sin((_time + _instance_id) * frequency) * amplitude;
    vertex_position.x += wind_offset;

    // wrap along edges
    vertex_position.xy = mod(vertex_position.xy, love_ScreenSize.xy);
    return transform * vertex_position;
}

#endif

#ifdef PIXEL // fragment shader

uniform float _time;
flat varying int _instance_id;

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    vec2 screen_size = love_ScreenSize.xy;

    // randomize alpha of each snowflake
    float alpha = (random(_instance_id) + 0.4) / 1.4;
    return vec4(1, 1, 1, alpha);
}
#endif
]]

--- @class SnowEffect
--- @field _n_snowflakes Number number of snowflakes, this is the absolute number, larger areas need more snowflakes for the same density
--- @field _data love.Mesh holds position information
--- @field _shape love.Mesh the actual dot-shape that will be rendered
--- @fiedl _shader love.Shader
--- @field _elapsed Number in seconds
rt.SnowEffect = function(n_snowflakes)

    local out = {
        _n_snowflakes = n_snowflakes,
        _data = love.graphics.newMesh(
                n_snowflakes, "points", "static"
        ),
        _shape = love.graphics.newMesh(
                {{0, 0}}, "points", "static"
        ),
        _shader = love.graphics.newShader(rt.snow_effect_shader_source),
        _elapsed = 0
    }

    -- set up attribute attachment so _shape can use the data in _data
    out._shape:attachAttribute("VertexPosition", out._data, "perinstance")

    -- randomize initial position of each snowflake in [0, 1]
    -- later scaled to screen resolution in shader
    for i = 1, n_snowflakes do
        out._data:setVertexAttribute(i, 1,
                love.math.random(),
                love.math.random()
        )
    end

    --- @brief update time uniform
    --- @param delta Number in seconds
    function out:update(delta)
        self._elapsed = self._elapsed + delta
        self._shader:send("_time", self._elapsed)
    end

    --- @brief draw to screen
    function out:draw()
        self:update(love.timer.getDelta())
        love.graphics.setShader(self._shader)
        love.graphics.drawInstanced(self._shape, self._n_snowflakes)
        love.graphics.setShader()
    end

    -- initialize shader uniforms
    out._shader:send("_instance_count", out._n_snowflakes)
    out:update(0)
    return out
end

-- usage
snow = rt.SnowEffect(3000)
function love.draw()
    snow:draw()
end
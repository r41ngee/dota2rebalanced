function PRDCalc(p, att)
    local N = floor(1/p)
    local C = 1 - (1-p)^(1/N)

    return RandomFloat(0, 1) < C * (att + 1)
end

function PRDCalc_Pct(p, att)
    return PRDCalc(p/100, att)
end
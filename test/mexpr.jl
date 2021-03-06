@testset "Constructor" begin
    @test_nowarn MExpr(:call)
    @test_nowarn MExpr(:call, Capture(:x))
    @test_throws ArgumentError MExpr(:call, Slurp(:x), Slurp(:y))
end

@testset "match" begin
    @testset "infix_match" begin
        infix_match = MExpr(:call, Capture(:op), Capture(:lexpr), Capture(:rexpr))
        expr1 = :(x + 10) 
        matches = match(infix_match, expr1)
        matches[:op] == :+
        matches[:lexpr] == :x
        matches[:rexpr] == 10

        expr2 = :(x .~ Normal(μ, σ))
        matches2 = match(infix_match, expr2)
        @test matches2[:lexpr] == :x
        @test matches2[:op] == :.~
        @test matches2[:rexpr] == :(Normal(μ, σ))
    end

    @testset "nested" begin
        expr = :( (x^3 + 10)  / 2)
        m_expr = MExpr(:call, :/, MExpr(:call, Capture(:plus), MExpr(:call, Capture(:power), :x, 3), 10), 2)
        matches = match(m_expr, expr)
        matches[:power] == :^
        matches[:plus] == :+
    end

    @testset "Slurp" begin
        expr = :((*)(1, 2, 3, 4)) 
        m_expr =  MExpr(:call, :*, Capture(:x))
        match(m_expr, expr) == nothing

        m_expr =  MExpr(:call, :*, Slurp(:args))
        match(m_expr, expr)[:args] == [1,2,3,4]

        m_expr =  MExpr(:call, :*, Capture(:start), Slurp(:args))
        matches = match(m_expr, expr)
        matches[:args] == [2,3,4]
        matches[:start] == 1

        m_expr =  MExpr(:call, :*, Slurp(:args), Capture(:end))
        matches = match(m_expr, expr)
        matches[:args] == [1,2,3]
        matches[:end] == 4

        m_expr =  MExpr(:call, :*, Capture(:start), Slurp(:args), Capture(:end))
        matches = match(m_expr, expr)
        matches[:start] == 1
        matches[:args] == [2,3]
        matches[:end] == 4

        isnumber = x->x isa Number
        number_expr = :((*)(1, 2, 3))
        string_expr = :((*)("1", "2", "3"))
        m_expr = MExpr(:call, :*, Slurp(x->all(isnumber.(x)), :numbers))
        @test match(m_expr, number_expr)[:numbers] == [1,2,3]
        @test match(m_expr, string_expr) == nothing
    end
end
@testset "OscarPolytope" begin

    pts = [1 0 0; 0 0 1]'
    lin = [0 1 0]
    Cone1=positive_hull(pts)
    Q0 = convex_hull(pts)
    Q1 = convex_hull(pts, [1 1])
    Q2 = convex_hull(pts, [1 1], [1 1])
    C0 = cube(2)
    C1 = cube(2, 0, 1)

    @testset "(de)homogenize" begin
        dehomogenize, homogenize = Oscar.dehomogenize, Oscar.homogenize

        m = [1 2 3; 4 5 6]'
        @test dehomogenize(homogenize(m, 0 // 1)) == m
        @test dehomogenize(homogenize(m)) == m
        @test dehomogenize(homogenize(pm.Matrix(m))) == m
        @test dehomogenize(homogenize(pm.Matrix{pm.Integer}(m))) isa pm.Matrix{pm.Integer}
        @test dehomogenize(homogenize(pm.Matrix{pm.Rational}(m))) isa pm.Matrix{pm.Rational}
    end

    @testset "conformance tests" begin
        @test typeof(Cone1) == Cone{fmpq}
        @test typeof(Q0) == Polyhedron{fmpq}
        @test typeof(Q1) == Polyhedron{fmpq}
        @test typeof(Q2) == Polyhedron{fmpq}
        @test typeof(C0) == Polyhedron{fmpq}
        @test typeof(C1) == Polyhedron{fmpq}
        @test typeof(Q0 == Q0) == Bool
        @test typeof(Q0 == Q1) == Bool
        @test typeof(Q0 != Q0) == Bool
        @test typeof(Q0 != Q1) == Bool
        @test Q0 != Q1
        @test C0 != C1
        @test C0 == C0
        @test typeof(dim(Q0)) == Int
        @test typeof(ambient_dim(Q0)) == Int
        @test collect(vertices(Q0)) == collect(vertices(convex_hull(vertices(Q0))))
    end

    @testset "convex_hull" begin
        @test size(point_matrix(vertices(Q0))) == (3, 2)
        @test size(point_matrix(vertices(Q1))) == (3, 2)
        @test size(vector_matrix(rays(Q1))) == (1, 2)
        @test size(generator_matrix(lineality_space(Q1))) == (0, 2)
        @test size(point_matrix(vertices(Q2))) == (2, 2)
        @test size(vector_matrix(rays(Q2))) == (0, 2)
        @test size(generator_matrix(lineality_space(Q2))) == (1, 2)
        @test dim(Q0) == 2
        @test dim(Q1) == 2
        @test dim(Q2) == 2
        @test ambient_dim(Q0) == 2
        @test ambient_dim(Q1) == 2
        @test ambient_dim(Q2) == 2
    end

    @testset "standard constructions" begin
        @test size(point_matrix(vertices(C0))) == (4, 2)
        @test C0 == convex_hull(vertices(C0))
        @test is_bounded(C0)
        @test is_smooth(C0)
        @test is_normal(C0)
        @test is_feasible(C0)
        @test is_fulldimensional(C0)
        @test minkowski_sum(C0,C0) == cube(2,-2,2)
        @test minkowski_sum(C0,C0; algorithm=:fukuda) == cube(2,-2, 2)
        @test intersect(C0,C0) == C0
    end

    @testset "newton_polytope" begin
        Qx, x = Oscar.PolynomialRing(Oscar.QQ, :x => 1:2)
        f = sum([x; 1])^2 + x[1]^4 * x[2] * 3
        newt = newton_polytope(f)
        @test dim(newt) == 2
        @test point_matrix(vertices(newt)) == matrix(QQ, [4 1; 2 0; 0 2; 0 0])
    end

    @testset "Construct from fmpq" begin
        A = zeros(Oscar.QQ, 3, 2)
        A[1, 1] = 1
        A[3, 2] = 4
        @test point_matrix(vertices(convex_hull(A))) == matrix(QQ, [1 0; 0 0; 0 4])

        lhs, rhs = halfspace_matrix_pair(facets(Polyhedron(A, [1, 2, -3])))
        @test lhs == matrix(QQ, [1 0; 0 4])
        @test rhs == [1, -3]
    end

    @testset "Construct from fmpz" begin
        A = zeros(Oscar.ZZ, 3, 2)
        A[1, 1] = 1
        A[3, 2] = 4
        @test point_matrix(vertices(convex_hull(A))) == matrix(QQ, [1 0; 0 0; 0 4])

        lhs, rhs = halfspace_matrix_pair(facets(Polyhedron(A, [1, 2, -3])))
        @test lhs == matrix(QQ, [1 0; 0 4])
        @test rhs == [1, -3]
    end
    
    @testset "SubObjectIterator/Matrix compatibility" begin
        Pos_poly = convex_hull([0 0 0], [1 0 0; 0 1 0; 0 0 1])
        Pos_cone = positive_hull([1 0 0; 0 1 0; 0 0 1])
        
        @test Oscar._ambient_dim([1, 2, 3, 4, 5]) == 5
        @test Oscar._ambient_dim([1 2 3 4; 5 6 7 8]) == 4
        @test Oscar._ambient_dim([[1, 2, 3], [4, 5, 6], [7, 8, 9], [0, 1, 2]]) == 3
        @test Oscar._ambient_dim(vertices(Pos_poly)) == 3
        @test Oscar._ambient_dim(collect(vertices(Pos_poly))) == 3
        
        # test for correctness of input interpretation for different types
        
        @test convex_hull(vertices(Pos_poly), rays(Pos_poly)) == Pos_poly
        @test positive_hull(rays(Pos_cone)) == Pos_cone
        
        @test convex_hull([-1 -1 -1], rays(Pos_cone)) == Pos_poly + [-1, -1, -1]
        @test positive_hull(rays(Pos_poly)) == Pos_cone
        
        @test convex_hull([[0, 0, 0]], [[1, 0, 0], [0, 1, 0], [0, 0, 1]]) == Pos_poly
        @test positive_hull([[1, 0, 0], [0, 1, 0], [0, 0, 1]]) == Pos_cone
        
        @test convex_hull([0 0 0], matrix(ZZ, [1 0 0; 0 1 0; 0 0 1])) == Pos_poly
        
        @test convex_hull(collect(vertices(Pos_poly)), collect(rays(Pos_poly))) == Pos_poly
        @test positive_hull(collect(rays(Pos_poly))) == Pos_cone
        
        @test convex_hull([0, 0, 0], rays(Pos_poly)) == Pos_poly
        @test rays(positive_hull([1, 0, 0]))[] == [1, 0, 0]
        
        @test Polyhedron(facets(Pos_poly)) == Pos_poly
        @test Polyhedron(facets(Pos_cone)) == Pos_poly
        
        @test cone_from_inequalities(facets(Pos_poly)) == Pos_cone
        @test cone_from_inequalities(facets(Pos_cone)) == Pos_cone
        
        @test Polyhedron(collect(facets(Pos_poly))) == Pos_poly
        @test Polyhedron(collect(facets(Pos_cone))) == Pos_poly
        
        @test cone_from_inequalities(collect(facets(Pos_poly))) == Pos_cone
        @test cone_from_inequalities(collect(facets(Pos_cone))) == Pos_cone
        
        # testing correct dispatch and tuple processing for Polyhedron
        @test Polyhedron([-1 0 0; 0 -1 0; 0 0 -1], [0, 0, 0]) == Pos_poly
        @test Polyhedron([[-1, 0, 0], [0, -1, 0], [0, 0, -1]], fmpq[0, 0, 0]) == Pos_poly
        @test Polyhedron(matrix(ZZ, [-1 0 0; 0 -1 0; 0 0 -1]), [0, 0, 0]) == Pos_poly
        @test Polyhedron(matrix(QQ, [-1 0 0; 0 -1 0; 0 0 -1]), [0, 0, 0]) == Pos_poly
        
        let y = convex_hull([0, 0, 0], [1, 0, 0], [[0, 1, 0], [0, 0, 1]])
            @test Polyhedron([-1 0 0], [0]) == y
            @test Polyhedron([-1 0 0], 0) == y
            @test Polyhedron([-[1, 0, 0]], fmpq[0]) == y
            @test Polyhedron([-1, 0, 0], fmpq[0]) == y
            @test Polyhedron([[-1, 0, 0]], fmpq(0)) == y
            @test Polyhedron([-1, 0, 0], fmpq(0)) == y
            @test Polyhedron(matrix(ZZ, [-1 0 0]), [0]) == y
            @test Polyhedron(matrix(QQ, [-1 0 0]), [0]) == y
        end
        
        let x = positive_hull([1 0 0; 0 1 0]), y = convex_hull([0 0 0], [1 0 0; 0 1 0])
            @test Polyhedron(facets(y), affine_hull(y)) == y
            @test Polyhedron(facets(y), linear_span(x)) == y
            
            @test cone_from_inequalities(facets(y), affine_hull(y)) == x
            @test cone_from_inequalities(facets(x), linear_span(x)) == x
            
            @test Polyhedron(facets(y), collect(affine_hull(y))) == y
            @test Polyhedron(facets(x), collect(linear_span(x))) == y
            
            @test cone_from_inequalities(facets(x), collect(affine_hull(y))) == x
            @test cone_from_inequalities(facets(y), collect(linear_span(x))) == x
        end
        
        # Here the content of the SubObjectIterator does not fit the idea of the
        # methods; we want ArgumentErrors to be thrown
        @test_throws ArgumentError convex_hull(facets(Pos_poly))
        @test_throws MethodError Polyhedron(vertices(Pos_poly)) #TODO
        @test_throws ArgumentError convex_hull(rays(Pos_poly))
        @test_throws ArgumentError convex_hull(rays(Pos_poly), [-1 -1 -1])
        @test_throws ArgumentError convex_hull([0 0 0], vertices(Pos_poly))
        @test_throws ArgumentError positive_hull(vertices(Pos_poly))
        @test_throws ArgumentError convex_hull(collect(rays(Pos_poly)))
        @test_throws ArgumentError convex_hull(vertices(Pos_poly), collect(vertices(Pos_poly)))
        @test_throws ArgumentError positive_hull(collect(vertices(Pos_poly)))
        
    end

end # of @testset "OscarPolytope"

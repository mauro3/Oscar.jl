export real_solutions, rational_solutions

@doc Markdown.doc"""
    real_solutions(I::MPolyIdeal, <keyword arguments>)

Given an ideal `I` with a finite solution set over the complex numbers, return a pair `r,p` where `p` is the rational parametrization of the solution set and `r` represents the real roots of `Ì`  with a given precision (default 32 bits).
See [BES21](@cite) for more information.

**Note**: At the moment only QQ is supported as ground field. If the dimension of `I`
is greater than zero an empty array is returned.

# Arguments
- `Ì::MPolyIdeal`: input ideal.
- `initial_hts::Int=17`: initial hash table size `log_2`.
- `nr_thrds::Int=1`: number of threads for parallel linear algebra.
- `max_nr_pairs::Int=0`: maximal number of pairs per matrix, only bounded by minimal degree if `0`.
- `la_option::Int=2`: linear algebra option: exact sparse-dense (`1`), exact sparse (`2`, default), probabilistic sparse-dense (`42`), probabilistic sparse(`44`).
- `info_level::Int=0`: info level printout: off (`0`, default), summary (`1`), detailed (`2`).
- `precision::Int=32`: bit precision for the computed solutions.

# Examples
```jldoctest
julia> R,(x1,x2,x3) = PolynomialRing(QQ, ["x1","x2","x3"])
(Multivariate Polynomial Ring in x1, x2, x3 over Rational Field, fmpq_mpoly[x1, x2, x3])

julia> I = ideal(R, [x1+2*x2+2*x3-1, x1^2+2*x2^2+2*x3^2-x1, 2*x1*x2+2*x2*x3-x2])
ideal(x1 + 2*x2 + 2*x3 - 1, x1^2 - x1 + 2*x2^2 + 2*x3^2, 2*x1*x2 + 2*x2*x3 - x2)

julia> real_solutions(I)
(Vector{fmpq}[[744483363399261433351//1180591620717411303424, 372241681699630716673//1180591620717411303424, -154187553040555781639//1180591620717411303424], [1, 0, 0], [71793683196126133110381699745//316912650057057350374175801344, 71793683196126133110381699745//633825300114114700748351602688, 173325283664805084153412401855//633825300114114700748351602688], [196765270119568550571//590295810358705651712, 1//590295810358705651712, 196765270119568550571//590295810358705651712]], AlgebraicSolving.RationalParametrization([:x1, :x2, :x3], fmpz[], 84*x^4 - 40*x^3 + x^2 + x, 336*x^3 - 120*x^2 + 2*x + 1, PolyElem[184*x^3 - 80*x^2 + 4*x + 1, 36*x^3 - 18*x^2 + 2*x]))
```
"""
function real_solutions(
        I::MPolyIdeal;                        # input generators
        initial_hts::Int=17,                  # hash table size, default 2^17
        nr_thrds::Int=1,                      # number of threads
        max_nr_pairs::Int=0,                  # number of pairs maximally chosen
                                              # in symbolic preprocessing
        la_option::Int=2,                     # linear algebra option
        info_level::Int=0,                    # info level for print outs
        precision::Int=32                     # precision of the solution set
        )
    AI = AlgebraicSolving.Ideal(I.gens.O)

    AlgebraicSolving.real_solutions(AI,
             initial_hts = initial_hts,
             nr_thrds = nr_thrds,
             max_nr_pairs = max_nr_pairs,
             la_option = la_option,
             info_level = info_level,
             precision = precision)

    return AI.real_sols, AI.rat_param
end

################################################################################
#
#  msolve interface for rational solutions
#
################################################################################

@doc Markdown.doc"""
    _rational_solutions(I::Ideal{T} where T <: MPolyElem, <keyword arguments>)

Given an ideal `I` with a finite solution set over the complex numbers, return
the rational roots of the ideal.

**Note**: At the moment only QQ is supported as ground field. If the dimension of `I`
is greater than zero an empty array is returned.

# Arguments
- `Ì::MPolyIdeal`: input ideal.
- `initial_hts::Int=17`: initial hash table size `log_2`.
- `nr_thrds::Int=1`: number of threads for parallel linear algebra.
- `max_nr_pairs::Int=0`: maximal number of pairs per matrix, only bounded by minimal degree if `0`.
- `la_option::Int=2`: linear algebra option: exact sparse-dense (`1`), exact sparse (`2`, default), probabilistic sparse-dense (`42`), probabilistic sparse(`44`).
- `info_level::Int=0`: info level printout: off (`0`, default), summary (`1`), detailed (`2`).
- `precision::Int=32`: bit precision for the computed solutions.

# Examples
```jldoctest
julia> R,(x1,x2,x3) = PolynomialRing(QQ, ["x1","x2","x3"])
(Multivariate Polynomial Ring in x1, x2, x3 over Rational Field, fmpq_mpoly[x1, x2, x3])

julia> I = ideal(R, [x1+2*x2+2*x3-1, x1^2+2*x2^2+2*x3^2-x1, 2*x1*x2+2*x2*x3-x2])
ideal(x1 + 2*x2 + 2*x3 - 1, x1^2 - x1 + 2*x2^2 + 2*x3^2, 2*x1*x2 + 2*x2*x3 - x2)

julia> rat_sols = Oscar._rational_solutions(I)
2-element Vector{Vector{fmpq}}:
 [1, 0, 0]
 [1//3, 0, 1//3]

julia> map(r->map(p->evaluate(p, r), I.gens), rat_sols)
2-element Vector{Vector{fmpq}}:
 [0, 0, 0]
 [0, 0, 0]
```
"""
function _rational_solutions(
        I::MPolyIdeal;                        # input generators
        initial_hts::Int=17,                  # hash table size, default 2^17
        nr_thrds::Int=1,                      # number of threads
        max_nr_pairs::Int=0,                  # number of pairs maximally chosen
                                              # in symbolic preprocessing
        la_option::Int=2,                     # linear algebra option
        info_level::Int=0,                    # info level for print outs
        precision::Int=32                     # precision of the solution set
        )

    @assert coefficient_ring(base_ring(I)) == QQ
    AI = AlgebraicSolving.Ideal(gens(I))

    AlgebraicSolving.rational_solutions(AI,
             initial_hts = initial_hts,
             nr_thrds = nr_thrds,
             max_nr_pairs = max_nr_pairs,
             la_option = la_option,
             info_level = info_level,
             precision = precision)

    return AI.rat_sols
end

################################################################################
#
#  Rational solutions of zero-dimensional ideals
#
################################################################################

"""
    rational_solutions(I::MPolyIdeal) -> Vector{Vector}

Given a zero-dimensional ideal, return all rational elements of the vanishing
set.

```jldoctest
julia> R, (x1,x2,x3) = PolynomialRing(QQ, ["x1","x2","x3"]);

julia> I = ideal(R, [x1+2*x2+2*x3-1, x1^2+2*x2^2+2*x3^2-x1, 2*x1*x2+2*x2*x3-x2]);

julia> rat_sols = rational_solutions(I)
2-element Vector{Vector{fmpq}}:
 [1, 0, 0]
 [1//3, 0, 1//3]

julia> map(r->map(p->evaluate(p, r), gens(I)), rat_sols)
2-element Vector{Vector{fmpq}}:
 [0, 0, 0]
 [0, 0, 0]
```
"""
function rational_solutions(I::MPolyIdeal{<:MPolyElem})
  gb = groebner_basis(I, ordering = lex(base_ring(I)))
  R = base_ring(I)
  if 1 in gb
    return elem_type(base_ring(R))[]
  end
  @req dim(I) == 0 "Dimension must be zero"
  @assert length(gb) == ngens(base_ring(I))
  R = base_ring(I)
  Qx, _ = PolynomialRing(base_ring(R), cached = false)
  rts = [elem_type(Qx)[zero(Qx) for i = gens(R)]]
  i = ngens(R)
  for f in gb
    sts = Vector{elem_type(Qx)}[]
    for r in rts
      r[i] = gen(Qx)
      g = evaluate(f, r)
      rt = roots(g)
      for x in rt
        r[i] = Qx(x)
        push!(sts, copy(r))
      end
    end
    rts = sts
    i -= 1
  end
  #for technical reasons (evaluation) the points are actually at this
  #point constant polynomials, hence:
  return [[constant_coefficient(x) for x in r] for r in rts]
end

function rational_solutions(I::MPolyIdeal{fmpq_mpoly})
  # Call msolve/AlgebraicSolving
  return _rational_solutions(I)
end

################################################################################
#
#  Rational solutions of one-dimensional homogenous ideals
#
################################################################################

"""
    rational_solutions(I::MPolyIdeal{<:MPolyElem_dec}) -> Vector{Vector}

Given a one-dimensional homogenous ideal, return all projective rational
elements of the vanishing set.
"""
function rational_solutions(I::MPolyIdeal{<:MPolyElem_dec})
  @req dim(I) == 1 "Dimension must be 1"
  #TODO: make this work for non-standard gradings
  S = base_ring(I)
  R = S.R
  RS, _ = PolynomialRing(base_ring(R), ngens(S) - 1, cached = false)
  Q = base_ring(R)
  all_S = Vector{elem_type(Q)}[]
  for i=1:ngens(S)
    val = [zero(RS) for l = gens(S)]
    k = 1
    for j in 1:ngens(S)
      if i == j
        val[j] = RS(1)
      else
        val[j] = gen(RS, k)
        k += 1
      end
    end
    #J should be an affine patch where the j-th var is set to 1
    J = ideal(RS, [evaluate(f, val) for f = gens(I)])
    r = rational_solutions(J)
    for s = r
      k = 1
      so = elem_type(Q)[]
      for j in 1:ngens(S)
        if i == j
          push!(so, one(Q))
        else
          push!(so, Q(s[k]))
          k += 1
        end
      end
      push!(all_S, so)
    end
  end
  P = proj_space(Q, ngens(RS))[1]
  #projective comparison!!!!
  return [p.v for p in Set(P(x) for x = all_S)]
end

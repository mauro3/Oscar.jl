export defines_automorphism,
       embedding_orthogonal_group

AutGrpAbTor = Union{AutomorphismGroup{GrpAbFinGen},AutomorphismGroup{TorQuadMod}}
AutGrpAbTorElem = Union{AutomorphismGroupElem{GrpAbFinGen},AutomorphismGroupElem{TorQuadMod}}
AbTorElem = Union{GrpAbFinGenElem,TorQuadModElem}

function _isomorphic_gap_group(A::GrpAbFinGen; T=PcGroup)
  iso = isomorphism(T, A)
  iso2 = inv(iso)
  return codomain(iso), iso, iso2
end

@doc Markdown.doc"""
    automorphism_group(G::GrpAbFinGen) -> AutomorphismGroup{GrpAbFinGen} 

Return the automorphism group of `G`.
"""
function automorphism_group(G::GrpAbFinGen)
  Ggap, to_gap, to_oscar = _isomorphic_gap_group(G)
  AutGAP = GAP.Globals.AutomorphismGroup(Ggap.X)
  aut = AutomorphismGroup(AutGAP, G)
  set_attribute!(aut, :to_gap => to_gap, :to_oscar => to_oscar)
  return aut
end


function apply_automorphism(f::AutGrpAbTorElem, x::AbTorElem, check::Bool=true)
  aut = parent(f)
  if check
    @assert parent(x) == aut.G "Not in the domain of f!"
  end
  to_gap = get_attribute(aut, :to_gap)
  to_oscar = get_attribute(aut, :to_oscar)
  xgap = to_gap(x)
  A = parent(f)
  domGap = parent(xgap)
  imgap = typeof(xgap)(domGap, GAPWrap.Image(f.X,xgap.X))
  return to_oscar(imgap)
end
 
(f::AutGrpAbTorElem)(x::AbTorElem)  = apply_automorphism(f, x, true)
Base.:^(x::AbTorElem,f::AutGrpAbTorElem) = apply_automorphism(f, x, true)

# the _as_subgroup function needs a redefinition
# to pass on the to_gap and to_oscar attributes to the subgroup
function _as_subgroup(aut::AutomorphismGroup{S}, subgrp::GapObj) where S <: Union{TorQuadMod,GrpAbFinGen}
  function img(x::S)
    return group_element(aut, x.X)
  end
  to_gap = get_attribute(aut, :to_gap)
  to_oscar = get_attribute(aut, :to_oscar)
  subgrp1 = AutomorphismGroup{S}(subgrp, aut.G)
  set_attribute!(subgrp1, :to_gap => to_gap, :to_oscar => to_oscar)
  return subgrp1, hom(subgrp1, aut, img)
end

@doc Markdown.doc"""
    hom(f::AutomorphismGroupElem{GrpAbFinGen}) -> GrpAbFinGenMap 

Return the element `f` of type `GrpAbFinGenMap`.
"""
function hom(f::AutGrpAbTorElem)
  A = domain(f)
  imgs = elem_type(A)[f(a) for a in gens(A)]
  return hom(A, A, imgs)
end


function (aut::AutGrpAbTor)(f::Union{GrpAbFinGenMap,TorQuadModMor};check::Bool=true)
  !check || (domain(f) === codomain(f) === domain(aut) && is_bijective(f)) || error("Map does not define an automorphism of the abelian group.")
  to_gap = get_attribute(aut, :to_gap)
  to_oscar = get_attribute(aut, :to_oscar)
  Agap = domain(to_oscar)
  AA = Agap.X
  function img_gap(x)
    a = to_oscar(group_element(Agap,x))
    b = to_gap(f(a))
    return b.X 
  end
  gene = GAPWrap.GeneratorsOfGroup(AA)
  img = GAP.Obj([img_gap(a) for a in gene])
  fgap = GAP.Globals.GroupHomomorphismByImagesNC(AA,AA,img)
  !check || fgap in aut.X || error("Map does not define an element of the group")
  return aut(fgap)
end


function (aut::AutGrpAbTor)(M::fmpz_mat; check::Bool=true)
  !check || defines_automorphism(domain(aut),M) || error("Matrix does not define an automorphism of the abelian group.")
  return aut(hom(domain(aut),domain(aut),M); check=check)
end

function (aut::AutGrpAbTor)(g::MatrixGroupElem{fmpq, fmpq_mat}; check::Bool=true)
  L = relations(domain(aut))
  if check
    B = basis_matrix(L)
    @assert can_solve(B, B*matrix(g),side=:left)
  end
  T = domain(aut)
  g = hom(T, T, elem_type(T)[T(lift(t)*matrix(g)) for t in gens(T)])
  return aut(g)
end

@doc Markdown.doc"""
    matrix(f::AutomorphismGroupElem{GrpAbFinGen}) -> fmpz_mat

Return the underlying matrix of `f` as a module homomorphism.
"""
matrix(f::AutomorphismGroupElem{GrpAbFinGen}) = hom(f).map


@doc Markdown.doc"""
    defines_automorphism(G::GrpAbFinGen, M::fmpz_mat) -> Bool

If `M` defines an endomorphism of `G`, return `true` if `M` defines an automorphism of `G`, else `false`.
""" 
defines_automorphism(G::GrpAbFinGen, M::fmpz_mat) = is_bijective(hom(G,G,M))

################################################################################
#
#   Special functions for orthogonal groups of torsion quadratic modules
#
################################################################################

"""
    _orthogonal_group(T::TorQuadMod, gensOT::Vector{fmpz_mat}) -> AutomorphismGroup{TorQuadMod}

Return the subgroup of the orthogonal group of `G` generated by `gensOT`.
"""
function _orthogonal_group(T::TorQuadMod, gensOT::Vector{fmpz_mat}; check::Bool=true)
  A = abelian_group(T)
  As, AstoA = snf(A)
  Ggap, to_gap, to_oscar = _isomorphic_gap_group(As)
  function toAs(x)
    return AstoA\A(x)
  end
  function toT(x)
    return T(AstoA(x))
  end
  T_to_As = Hecke.map_from_func(toAs, T, As)
  As_to_T = Hecke.map_from_func(toT, As, T)
  to_oscar = compose(to_oscar, As_to_T)
  to_gap = compose(T_to_As, to_gap)
  AutGAP = GAP.Globals.AutomorphismGroup(Ggap.X)
  ambient = AutomorphismGroup(AutGAP, T)
  set_attribute!(ambient, :to_gap => to_gap, :to_oscar => to_oscar)
  gens_aut = GapObj([ambient(g, check=check).X for g in gensOT])  # performs the checks
  if check
    # expensive for large groups
    subgrp_gap =GAP.Globals.Subgroup(ambient.X, gens_aut)
  else
    subgrp_gap =GAP.Globals.SubgroupNC(ambient.X, gens_aut)
  end
  aut = AutomorphismGroup(subgrp_gap, T)
  set_attribute!(aut, :to_gap => to_gap, :to_oscar => to_oscar)
  return aut
end

function Base.show(io::IO, aut::AutomorphismGroup{TorQuadMod})
  T = domain(aut)
  print(IOContext(io, :compact => true), "Group of isometries of ", T , " generated by ", length(gens(aut)), " elements")
end


@doc Markdown.doc"""
    matrix(f::AutomorphismGroupElem{TorQuadMod}) -> fmpz_mat

Return a matrix inducing `f`.
"""
matrix(f::AutomorphismGroupElem{TorQuadMod}) = hom(f).map_ab.map

@doc Markdown.doc"""
    defines_automorphism(G::TorQuadMod, M::fmpz_mat) -> Bool

If `M` defines an endomorphism of `G`, return `true` if `M` defines an automorphism of `G`, else `false`.
"""
function defines_automorphism(G::TorQuadMod, M::fmpz_mat)
  g = hom(G, G, M)
  if !is_bijective(g)
    return false
  end
  # check that the form is preserved
  B = gens(G)
  n = length(B)
  for i in 1:n
    if Hecke.quadratic_product(B[i]) != Hecke.quadratic_product(g(B[i]))
      return false
    end
    for j in 1:i-1
      if B[i]*B[j] != g(B[i])*g(B[j])
        return false
      end
    end
  end
  return true
end

function Base.show(io::IO, ::MIME"text/plain", f::AutomorphismGroupElem{T}) where T<:TorQuadMod
  D = domain(parent(f))
  print(IOContext(io, :compact => true), "Isometry of ", D, " defined by \n")
  print(io, matrix(f))
end

function Base.show(io::IO, f::AutomorphismGroupElem{T}) where T<:TorQuadMod
  print(io, matrix(f))
end


@doc Markdown.doc"""
    orthogonal_group(T::TorQuadMod)  -> AutomorphismGroup{TorQuadMod}

Return the full orthogonal group of this torsion quadratic module.
"""
@attr AutomorphismGroup function orthogonal_group(T::TorQuadMod)
  if is_trivial(abelian_group(T))
    return _orthogonal_group(T, fmpz_mat[identity_matrix(ZZ, ngens(T))], check = false)
  elseif is_semi_regular(T)
    # if T is semi-regular, it is isometric to its normal form for which
    # we know how to compute the isometries.
    N, i = normal_form(T)
    j = inv(i)
    gensOT = _compute_gens(N)
    gensOT = TorQuadModMor[hom(N, N, g) for g in gensOT]
    gensOT = fmpz_mat[compose(compose(i,g),j).map_ab.map for g in gensOT]
    unique!(gensOT)
    length(gensOT) > 1 ? filter!(m -> !isone(m), gensOT) : nothing
  elseif iszero(gram_matrix_quadratic(T))
    # in that case, we don't have any conditions regarding the
    # quadratic form, so we have all automorphisms coming
    # from the underlying abelian group
    gensOT = [matrix(g) for g in gens(automorphism_group(abelian_group(T)))]
  else
    # if T is not semi-regular, we distinghuish the cases whether or not
    # it splits its radical quadratic
    i = radical_quadratic(T)[2]
    gensOT = has_complement(i)[1] ? _compute_gens_split_degenerate(T) : _compute_gens_non_split_degenerate(T)
  end
  return _orthogonal_group(T, gensOT, check=false)
end

@doc Markdown.doc"""
    embedding_orthogonal_group(i::TorQuadModMor) -> GAPGroupHomomorphism

Given an embedding $i\colon A \to D$ between two torsion quadratic modules,
such that `A` admits a complement `B` in $D \cong A \oplus B$, return the
embedding $O(A) \to O(D)$ obtained by extending the isometries of `A` by
the identity on `B`.
"""
function embedding_orthogonal_group(i::TorQuadModMor)
  @req is_injective(i) "i must be injective"
  ok, j = has_complement(i)
  @req ok "The domain of i must have a complement in the codomain"
  A = domain(i)
  B = domain(j)
  D = codomain(i)
  Dorth = direct_sum(A, B)[1]
  ok, phi = is_isometric_with_isometry(Dorth, D)
  @assert ok
  OD = orthogonal_group(D)
  OA = orthogonal_group(A)

  geneOAinDorth = TorQuadModMor[]
  for f in gens(OA)
    m = block_diagonal_matrix([matrix(f), identity_matrix(ZZ, ngens(B))])
    m = hom(Dorth, Dorth, m)
    push!(geneOAinDorth, m)
  end
  geneOAinOD = [OD(compose(inv(phi), compose(g, phi)), check = false) for g in geneOAinDorth]
  OAtoOD = hom(OA, OD, geneOAinOD, check = false)
  return OAtoOD::GAPGroupHomomorphism{AutomorphismGroup{TorQuadMod}, AutomorphismGroup{TorQuadMod}}
end


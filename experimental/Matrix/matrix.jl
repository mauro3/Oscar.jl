module MatrixGroups

using GAP
using Oscar
import Oscar:GAPWrap

export _wrap_for_gap
  
################################################################################
# Initialize GAP function, i.e. GAP reads the file matrix.g
#
function __init__()
    GAP.Globals.Reread(GAP.GapObj(joinpath(Oscar.oscardir, "experimental", "Matrix", "matrix.g")))
end

################################################################################
# Computes the JuliaMatrixRep of a MatrixElem in GAP
#
#    _wrap_for_gap(m::MatrixElem)
#
# Input: m::MatrixElem
# Output: Returns the JuliaMatrixRep of m in GAP
#
# Example
# ```jldoctest
# julia> m = matrix(ZZ, [0 1 ; -1 0]);
# julia> _wrap_for_gap(m)
# GAP: <matrix object of dimensions 2x2 over Integer Ring>
# ```
# """
function _wrap_for_gap(m::MatrixElem)
    return GAP.Globals.MakeJuliaMatrixRep(m)
end


################################################################################
# Construct a GAP group where the elements on the GAP side are wrappers of type
# JuliaMatrixRep around the Oscar matrices.
# Moreover, if G is finite then a nice morphism from G into a GAP matrix group G2
# over a finite field is constructed such that calculations in G can be handled
# automatically  by transferring them to G2.
#
#     MatrixGroup(matrices::Vector{<:MatrixElem{T}}) where T <: Union{fmpz, fmpq, nf_elem}
#
# Input: matrices::Vector{<:MatrixElem{T}} where T <: Union{fmpz, fmpq, nf_elem}
# Output: GAP group generated by the JuliaMatrixReps of matrices
#
# Example
# ```jldoctest
# julia> m1 = matrix(QQ, [0 1 ; -1 0]);
# julia> m2 = matrix(QQ, [ -1 0; 0 1]);
# julia> MatrixGroup([m1,m2])
# GAP: <group with 2 generators>
# ```
# """
function MatrixGroup(matrices::Vector{<:MatrixElem{T}}) where T <: Union{fmpz, fmpq, nf_elem}
       @assert !isempty(matrices)
    
       # Check whether all matrices are n by n (and invertible and such ...)
       
       n = nrows(matrices[1])
       is_invertible(x) = is_unit(det(x))
       K = base_ring(matrices[1])
       for mat in matrices
            if K != mat.base_ring
                error("Matrices are not from the same base ring.")
            end
            if !is_invertible(mat)
                error("At least one matrix is not invertible.")
            end
            if size(mat) != (n, n)
                error("At least one matrix is not square or not of the same size.")
            end
       end
       if K isa FlintIntegerRing
          K = QQ
       end

       Fq, matrices_Fq, OtoFq = Oscar.good_reduction(matrices, 2)

       ele = matrices_Fq[1]
       hom = Oscar._iso_oscar_gap(ele.base_ring)
        
       gap_matrices_Fq = GAP.Obj([map_entries(hom, m) for m in matrices_Fq])
       G2 = GAP.Globals.Group(gap_matrices_Fq)
       N = fmpz(GAPWrap.Order(G2))
       if !is_divisible_by(Hecke._minkowski_multiple(K, n), N)
          error("Group is not finite")
       end

       G_to_fin_pres = GAP.Globals.IsomorphismFpGroupByGenerators(G2, gap_matrices_Fq)
       F = GAPWrap.Range(G_to_fin_pres)
       rels = GAPWrap.RelatorsOfFpGroup(F)

       gens_and_invsF = [ g for g in GAPWrap.FreeGeneratorsOfFpGroup(F) ]
       append!(gens_and_invsF, [ inv(g) for g in GAPWrap.FreeGeneratorsOfFpGroup(F) ])
       matrices_and_invs = copy(matrices)
       append!(matrices_and_invs, [ inv(M) for M in matrices ])
       for i = 1:length(rels)
          M = GAP.Globals.MappedWord(rels[i], GapObj(gens_and_invsF), GapObj(matrices_and_invs))
          if !isone(M)
             error("Group is not finite")
          end
       end
        
       gapMatrices = GAP.Obj([Oscar.MatrixGroups._wrap_for_gap(m) for m in matrices])
       G = GAP.Globals.Group(gapMatrices)
       
       JuliaGAPMap = GAP.Globals.GroupHomomorphismByImagesNC(G,G2,GAPWrap.GeneratorsOfGroup(G2))
       
       GAP.Globals.SetNiceMonomorphism(G,JuliaGAPMap);
       GAP.Globals.SetIsHandledByNiceMonomorphism(G, true);
       
       return G
end

function _lex_isless(a::T,b::T) where T<:MatElem{S} where S <: Union{fmpz, fmpq}
  @assert base_ring(a) === base_ring(b)
  @assert size(a) == size(b)
  for i in 1:nrows(a), j in 1:ncols(a)
    if a[i,j] != b[i,j]
      return a[i,j] < b[i,j]
    end
  end
  return false
end

function _lex_isEqual(a::T,b::T) where T<:MatElem
  @assert base_ring(a) === base_ring(b)
  @assert size(a) == size(b)
  for i in 1:nrows(a), j in 1:ncols(a)
    if a[i,j] != b[i,j]
      return false
    end
  end
  return true
end

end #module MatrixGroups


using .MatrixGroups

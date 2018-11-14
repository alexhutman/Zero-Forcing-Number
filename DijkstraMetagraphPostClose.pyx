import itertools
import heapq
import random

DijkstraMG = None

def shortest(v, path_so_far, predecessor_list, start):
    predecessor_of_v = predecessor_list[v]
    path_so_far.insert(0,predecessor_of_v)
    
    if predecessor_of_v[0] != start:
        shortest(predecessor_of_v[0], path_so_far, predecessor_list, start)
    return path_so_far

def build_zf_set(final_metavx_list):
    global DijkstraMG #To access the graph's neighbors

    zf_set = set()

    for (filled_vertices, forcing_vx) in final_metavx_list[:-1]: #Do not need to do the last metavertex (everything is already filled)
        if forcing_vx not in filled_vertices: #If filled, don't need to add it to zf_set since it will already have been gotten for free
            zf_set.add(forcing_vx)
#        filled_set.add(forcing_vx) #Fill forcing vertex
        unfilled_neighbors = DijkstraMG.neighbors_dict[forcing_vx] - filled_vertices #Find n unfilled neighbors of forcing vertex
    
        if len(unfilled_neighbors)-1 > 0:
            zf_set.update(set(itertools.islice(unfilled_neighbors, len(unfilled_neighbors)-1))) #Pick n-1 of them, the last will be gotten for free
#        filled_set.update(DijkstraMG.neighbors_dict[forcing_vx]) #Fill all of the neighbors
    return zf_set

def dijkstra(metagraph, start, target):
    return real_dijkstra(metagraph, start, target)

cdef real_dijkstra(metagraph, start, target):
    global DijkstraMG
    DijkstraMG = metagraph

    cdef set previous_closure
    cdef set vx_and_neighbors
    
    cdef frozenset current
    cdef dict previous
    cdef list unvisited_queue
    
    cdef int current_distance
    cdef int cost_of_making_it_force
    cdef int what_forced
    cdef int new_dist
    
    
    previous = {}
    unvisited_queue = [(0, start, None)]
    heapq.heapify(unvisited_queue)

    done = False
    while not done:
        uv = heapq.heappop(unvisited_queue)
        
        current_distance = uv[0]
        parent = uv[1]
        vx_that_is_to_force = uv[2]

        previous_closure = set(parent)
        vx_and_neighbors = set([])
        if vx_that_is_to_force != None:
            vx_and_neighbors = set([vx_that_is_to_force])
            vx_and_neighbors.update(set(metagraph.neighbors_dict[vx_that_is_to_force]))
        current = metagraph.extend_closure(previous_closure, vx_and_neighbors)

        # whether vertex is in 'previous' is proxy for if it has been visited
        if current in previous:
            continue

#        superset_has_been_visited = False
#        for seen_set in previous:
#            if current.issubset(seen_set):
#                superset_has_been_visited = True
#                break
#        if superset_has_been_visited:
#            print "yay"
#            continue
            
            
        previous[current] = (parent, vx_that_is_to_force)

        if current == target: # We have found the target vertex, can stop searching now
            done = True
            break
            
        for neighbor_tuple in metagraph.neighbors_with_edges(current):
            what_forced = neighbor_tuple[1]
            cost_of_making_it_force = neighbor_tuple[0]
            
            new_dist = current_distance + cost_of_making_it_force
            
            heapq.heappush(unvisited_queue, (new_dist, current, what_forced))

            
    temp = [(target, None)]
    shortest_path = shortest(target, temp, previous, start)

    print "Closures remaining on queue:                ", len(unvisited_queue)
    print "Length of shortest path found in metagraph: ", len(shortest_path)
#    print "Shortest path found: ", shortest_path

    
    return build_zf_set(shortest_path)
(: Copyright 2013 The Perseus Project, Tufts University, Medford MA
This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
See http://www.gnu.org/licenses/. 
:)


declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace cts="http://chs.harvard.edu/xmlns/cts/ti";
declare namespace atom="http://www.w3.org/2005/Atom";


declare variable $e_dir as xs:string external; 

let $collection := collection($e_dir)
let $textgroups := distinct-values($collection//cts:textgroup/@urn)
let $proto_feed := ($collection/atom:feed)[1]
let $allgroups :=
    for $textgroup in $textgroups 
        let $allfeeds := $collection/atom:feed[//cts:textgroup[@urn = $textgroup]]
        let $allworks := for $w in $allfeeds//cts:work order by $w/@urn return $w
        let $all_mods := 
            for $entry in $allfeeds//atom:entry[atom:id[matches(.,concat('.*?/',$textgroup ,'\..*/atom#mods'))]]
            return 
                element atom:entry {
                    $entry/atom:id,
                    $entry/atom:link,
                    $entry/atom:author,
                    $entry/atom:title
                }
        let $distinct_mads := distinct-values($allfeeds//atom:entry[atom:id[matches(.,concat('.*?/',$textgroup ,'\..*/atom#mads.*'))]]/atom:link[@rel='alternate']/@href)
        let $all_mads :=
            for $author at $a_i in $distinct_mads return
                let $proto_mads :=
                   ($allfeeds//atom:entry[atom:link[@rel='alternate' and @href = $author]])[1]
                let $proto_id := substring-before(substring-before($proto_mads/atom:id,'/atom#mads'),$textgroup)
                return 
                    element atom:entry {
                        element atom:id { concat( $proto_id,$textgroup,'/atom#mads-',$a_i) },
                        $proto_mads/atom:link[@rel='alternate'],
                        $proto_mads/atom:author,
                        element atom:title { 
                            concat('The Perseus Catalog: MADS file for author in CTS textgroup ' , $textgroup)
                        }
                    }
        let $proto := ($collection//cts:textgroup[@urn = $textgroup])[1]
        return 
            element cts:textgroup {
                $proto/@*,
                $proto/cts:groupname,
                $allworks,
                $all_mods,
                $all_mads
            }
let $ti :=
    element cts:TextInventory {
        attribute tiversion {"4.0"},
        ($collection//cts:TextInventory)[1]/*[not(local-name(.) = 'textgroup')],
        for $group in $allgroups
        order by $group/@urn
        return $group
    }

return 
    element atom:feed {
        $proto_feed/atom:author,
        $proto_feed/atom:updated,
        $proto_feed/atom:rights,
        element atom:entry {
            element atom:id { 'TextInventory'},
            element atom:content {
                attribute type { 'text/xml' },
                $ti
            }
        }
    }
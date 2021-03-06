# Ruby port of a java port of Sequitur. Original copyright below.
# (c) 2010, Ben Nagy
#
=begin
This class is part of a Java port of Craig Nevill-Manning's Sequitur algorithm.
Copyright (C) 1997 Eibe Frank

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
=end

require 'seq_node'
require 'base64'

class Terminal < Node
    def initialize( value )
        self.val=value
        super()
    end

    # This is a shitty hack until I work out why YAML
    # can't serialise \n correctly.
    def val=( value )
        #@val=Base64.encode64( value )
        @val=value
    end

    def val
        #Base64.decode64( @val )
        @val
    end

    def cleanup
        join self.prev, self.next
        delete_digram
    end

    def clone
        new=Terminal.new( val )
        new.prev=self.prev
        new.next=self.next
        new
    end

    def inspect
        "#{self.object_id}T#{@val.inspect}<#{(prev.rule.number rescue '')}>"
    end
end


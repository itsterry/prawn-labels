# labels.rb :  A simple helper to generate labels for Prawn PDFs
#
# Copyright February 2010, Jordan Byron. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'prawn/layout'

module Prawn    
  class Labels
    attr_reader :document, :type
    
    def self.generate(file_name, data, options = {}, &block)                               
      labels = Labels.new(data, options,&block)
      
      labels.document.render_file(file_name)
    end
    
    def initialize(data, options={}, &block)
      types_file = File.join(File.dirname(__FILE__), 'types.yaml')
      types      = YAML.load_file(types_file)
      
      unless @type = types[options[:type]]
        raise "Label Type Unknown '#{options[:type]}'" 
      end

      @document = Document.new  :left_margin  => type["left_margin"], 
                                :right_margin => type["right_margin"],
                                :page_size=>type["page_size"]

                                
      generate_grid @type
      
      data.each_with_index do |record, i|
        create_label(i, record) do |pdf, record|
          yield pdf, record
        end
      end
      
    end
    
    private
    
    def generate_grid(type)
      
      @document.instance_eval do
        define_grid  :columns       => type["columns"], 
                     :rows          => type["rows"], 
                     :column_gutter => type["column_gutter"],
                     :row_gutter    => type["row_gutter"]
      end
    end
  
    def row_col_from_index(i)
      index = (@document.page_number - 1) * (@document.grid.rows * @document.grid.columns)
      
      @document.grid.rows.times do |r|    
        @document.grid.columns.times do |c|
          if index == i
            return [r,c]
          else
            index += 1
          end
        end
      end
      
      @document.start_new_page
      generate_grid @type
      [0,0]
    end
  
    def create_label(i,record,&block)
      p = row_col_from_index(i)

      b = @document.grid(p.first, p.last)
      @document.bounding_box b.top_left, :width => b.width, :height => b.height do
        if record.is_a?(Array) and not record.empty?
          record.each{|r| yield(@document, r)}
        else
          yield(@document, record)
        end
      end
    end
  end
end
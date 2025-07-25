describe("Koptinterface module", function()
    local DocumentRegistry, Koptinterface
    setup(function()
        require("commonrequire")
        DocumentRegistry = require("document/documentregistry")
        Koptinterface = require("document/koptinterface")
    end)

    describe("should", function()

        local doc

        setup(function()
            doc = DocumentRegistry:openDocument("spec/front/unit/data/tall.pdf")
            doc.configurable.text_wrap = 0
        end)

        teardown(function()
            doc:close()
        end)

        it("should get auto bbox", function()
            local auto_bbox = Koptinterface:getAutoBBox(doc, 1)
            assert.is.near(22, auto_bbox.x0, 0.5)
            assert.is.near(38, auto_bbox.y0, 0.5)
            assert.is.near(548, auto_bbox.x1, 0.5)
            assert.is.near(1387, auto_bbox.y1, 0.5)
        end)

        it("should get semi auto bbox", function()
            local semiauto_bbox = Koptinterface:getSemiAutoBBox(doc, 1)
            local page_bbox = doc:getPageBBox(1)
            doc.bbox[1] = {
                x0 = page_bbox.x0 + 10,
                y0 = page_bbox.y0 + 10,
                x1 = page_bbox.x1 - 10,
                y1 = page_bbox.y1 - 10,
            }

            local bbox = Koptinterface:getSemiAutoBBox(doc, 1)
            assert.is_not.near(semiauto_bbox.x0, bbox.x0, 0.5)
            assert.is_not.near(semiauto_bbox.y0, bbox.y0, 0.5)
            assert.is_not.near(semiauto_bbox.x1, bbox.x1, 0.5)
            assert.is_not.near(semiauto_bbox.y1, bbox.y1, 0.5)
        end)

        it("should render optimized page to de-watermark", function()
            local page_dimen = doc:getPageDimensions(1, 1.0, 0)
            local tile = Koptinterface:renderOptimizedPage(doc, 1, nil,
            1.0, 0, false)
            assert.truthy(tile)
            assert.are.same(page_dimen, tile.excerpt)
        end)

        it("should reflow page in foreground", function()
            doc.configurable.text_wrap = 1
            local kc = Koptinterface:getCachedContext(doc, 1)
            assert.truthy(kc)
        end)

        it("should hint reflowed page in background", function()
            doc.configurable.text_wrap = 1
            Koptinterface:hintReflowedPage(doc, 1, 1.0, 0, 1.0, 255, false)
            -- and wait for reflowing to complete
            local kc = Koptinterface:getCachedContext(doc, 1)
            assert.truthy(kc)
        end)

        it("should get native text boxes", function()
            Koptinterface:getCachedContext(doc, 1)
            local boxes = Koptinterface:getNativeTextBoxes(doc, 1)
            assert.equal(60, #boxes)
        end)

        it("should get native text boxes from scratch", function()
            Koptinterface:getCachedContext(doc, 1)
            local boxes = Koptinterface:getNativeTextBoxesFromScratch(doc, 1)
            assert.equal(60, #boxes)
        end)

        it("should get reflow text boxes", function()
            doc.configurable.text_wrap = 1
            Koptinterface:getCachedContext(doc, 1)
            local boxes = Koptinterface:getReflowedTextBoxes(doc, 1)
            local lines_in_reflowed_page = #boxes
            assert.truthy(lines_in_reflowed_page > 60)
        end)

        it("should get reflow text boxes from scratch", function()
            doc.configurable.text_wrap = 1
            Koptinterface:getCachedContext(doc, 1)
            local boxes = Koptinterface:getReflowedTextBoxesFromScratch(doc, 1)
            local lines_in_reflowed_page = #boxes
            assert.truthy(lines_in_reflowed_page > 60)
        end)

    end)

    describe("should", function()

        local complex_doc

        setup(function()
            complex_doc = DocumentRegistry:openDocument("spec/front/unit/data/sample.pdf")
            complex_doc.configurable.text_wrap = 0
        end)

        teardown(function()
            complex_doc:close()
        end)

        it("should get page block of a two-column page", function()
            for i = 0.3, 0.6, 0.3 do
                for j = 0.3, 0.6, 0.3 do
                    local block = Koptinterface:getPageBlock(complex_doc, 34, i, j)
                    assert.truthy(block.x1 - block.x0 < 0.5)
                end
            end
        end)

        it("should get word from native position", function()
            local word_boxes = Koptinterface:getWordFromPosition(complex_doc, {
                page = 19, x = 400, y = 530,
            })
            assert.is.same("previous", word_boxes.word)
        end)

        it("should get word from reflow position", function()
            complex_doc.configurable.text_wrap = 1
            Koptinterface:getCachedContext(complex_doc, 19)
            local word_boxes = Koptinterface:getWordFromPosition(complex_doc, {
                page = 19, x = 320, y = 730,
            })
            assert.is.same("time,", word_boxes.word)
        end)

    end)

    describe("should", function()

        local paper_doc

        setup(function()
            paper_doc = DocumentRegistry:openDocument("spec/front/unit/data/paper.pdf")
            paper_doc.configurable.text_wrap = 0
        end)

        teardown(function()
            paper_doc:close()
        end)

        it("should get link from native position", function()
            local link = Koptinterface:getLinkFromPosition(paper_doc, 1, {
                x = 140, y = 560,
            })
            assert.truthy(link)
            assert.is.same(20, link.page)
            require("dbg"):v("link", link)
        end)

        it("should get link from reflow position", function()
            paper_doc.configurable.text_wrap = 1
            local link = Koptinterface:getLinkFromPosition(paper_doc, 1, {
                x = 455, y = 1105,
            })
            assert.truthy(link)
            assert.is.same(20, link.page)
        end)

    end)

end)

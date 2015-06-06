create procedure CreateCatalogExportXml @CatalogNodeCode nvarchar(20), @Output xml output as
set @Output = (select 
	1.0 [@Version],
	(
		select
			case c.IsActive when 1 then 'True' else 'False' end [@isActive],
			c.SortOrder [@sortOrder],
			c.DefaultLanguage [@defaultLanguage],
			c.WeightBase [@weightBase],
			c.DefaultCurrency [@defaultCurrency],
			Convert(datetime,'2199-01-01',127) [@endDate], --c.EndDate [@endDate],
			c.StartDate [@startDate],
			c.Modified [@lastmodified],
			c.Name [@name],
			-- Language
			(
				select 
					cl.LanguageCode,
					cl.UriSegment
				from CatalogLanguage cl
				where cl.CatalogId = c.CatalogId
				for xml path ('Language'), root ('Languages'), type
			),
			-- Nodes
			(
				select 
					COUNT(*) [@totalCount],
					(
						-- Node
						select 
							cn.Name,
							cn.StartDate,
							Convert(datetime,'2199-01-01',127) EndDate, --cn.EndDate,
							case cn.IsActive when 1 then 'True' else 'False' end IsActive,
							cn.SortOrder,
							-- 'default' DisplayTemplate,
							Code,
							(
								-- MetaData
								select
								(
									-- MetaClass
									select Name
									From MetaClass
									where MetaClassId = cn.MetaClassId
									for xml path ('MetaClass'), type
								),
								(
									-- MetaFields
									select
										mf.Name, 
										case mdt.Name
											when 'EnumSingleValue' then 'DictionarySingleValue'
											when 'EnumMultiValue' then 'DictionaryMultiValue'
											else mdt.Name
										end [Type],
										(
											select 
												[Language] [@language],
												case mf.Name
													when 'DisplayName' then IsNull(case mf.MultiLanguageValue when 1 then lang.DisplayName else lang.DisplayName end, '')
													when 'Description' then IsNull(case mf.MultiLanguageValue when 1 then lang.[Description] else lang.[Description] end, '')
													else ''
												end [@value] 
											from CatalogNodeEx_Localization lang
											where ObjectId = cn.CatalogNodeId
											for xml path('Data'), type
										)
									from MetaField mf
										inner join MetaClassMetaFieldRelation mcmfr
											on mf.MetaFieldId = mcmfr.MetaFieldId
										inner join MetaDataType mdt
											on mf.DataTypeId = mdt.DataTypeId
									where 
										mf.SystemMetaClassId = 0
										and mcmfr.Enabled = 1 
										and mcmfr.MetaClassId = (select MetaClassId from MetaClass where [Namespace] = 'Mediachase.Commerce.Catalog.User' and Name = 'CatalogNodeEx')
									for xml path ('MetaField'), root('MetaFields'), type
								)
								for xml path ('MetaData'), type
							),
							-- ParentNode
							(
								select 
								(
									select Code from CatalogNode where CatalogNodeId = cn.ParentNodeId
								)
								for xml path ('ParentNode'), type
							),
							-- Seo
							(
								select 
									LanguageCode,
									Uri,
									Title,
									Keywords,
									UriSegment
								from CatalogItemSeo
								where CatalogEntryId is null and CatalogId = c.CatalogId and CatalogNodeId = cn.CatalogNodeId
								for xml path ('Seo'), root ('SeoInfo'), type
							)
						from CatalogNode cn
							inner join CatalogNodeEx cne
								on cn.CatalogNodeId = cne.ObjectId
						where cn.Code = @CatalogNodeCode and cn.CatalogId = c.CatalogId
						for xml path ('Node'), type	
					) 
				from CatalogNode
				where Code = @CatalogNodeCode and CatalogId = c.CatalogId
				for xml path('Nodes'), type
			),
			-- Entries
			(
				select 
					(
						-- TotalCount
						select count(*)
						from CatalogEntry ce
							inner join NodeEntryRelation ner
								on ce.CatalogEntryId = ner.CatalogEntryId
							inner join CatalogNode cn
								on ner.CatalogNodeId = cn.CatalogNodeId
						where cn.Code = @CatalogNodeCode and ce.CatalogId = c.CatalogId
					)  [@totalCount],
					(
						-- Entry
						select
							ce.StartDate,
							Convert(datetime,'2199-01-01',127) EndDate, --ce.EndDate,
							ce.Name,
							case ce.IsActive when 1 then 'True' else 'False' end IsActive,
							'Entry' [EntryType],
							ce.Code,
							(
								-- MetaClass
								select
								(
									select Name 
									from MetaClass
									where MetaClassId = ce.MetaClassId
									for xml path ('MetaClass'), type
								),
								-- MetaFields
								(
									select 
										mf.Name, 
										case mdt.Name
											when 'EnumSingleValue' then 'DictionarySingleValue'
											when 'EnumMultiValue' then 'DictionaryMultiValue'
											else mdt.Name
										end [Type],
										case 
											-- EnumSingleValue
											when mdt.Name = 'EnumSingleValue' then
												(
													select 
														[Language] [@language],
														case mf.Name
															when 'granskad' then case mf.MultiLanguageValue when 1 then lang.granskad else book.granskad end
															when 'mediatyp' then case mf.MultiLanguageValue when 1 then lang.mediatyp else book.mediatyp end
															when 'omfang_typ' then case mf.MultiLanguageValue when 1 then lang.omfang_typ else book.omfang_typ end
															when 'paket' then case mf.MultiLanguageValue when 1 then lang.paket else book.paket end
															when 'paket_typ' then case mf.MultiLanguageValue when 1 then lang.paket_typ else book.paket_typ end
															when 'illustrerad' then case mf.MultiLanguageValue when 1 then lang.illustrerad else book.illustrerad end
															when 'laromedel' then case mf.MultiLanguageValue when 1 then lang.laromedel else book.laromedel end
															when 'aldersgrupp' then case mf.MultiLanguageValue when 1 then lang.aldersgrupp else book.aldersgrupp end
															when 'original' then case mf.MultiLanguageValue when 1 then lang.original else book.original end
															when 'miljomarkning' then case mf.MultiLanguageValue when 1 then lang.miljomarkning else book.miljomarkning end
															else -1
														end [@key],
														case mf.Name
															when 'granskad' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.granskad)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.granskad)
																)
															)
															when 'mediatyp' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.mediatyp)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.mediatyp)
																)
															)
															when 'omfang_typ' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.omfang_typ)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.omfang_typ)
																)
															)
															when 'paket' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.paket)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.paket)
																)
															)
															when 'paket_typ' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.paket_typ)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.paket_typ)
																)
															)
															when 'illustrerad' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.illustrerad)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.illustrerad)
																)
															)
															when 'laromedel' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.laromedel)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.laromedel)
																)
															)
															when 'aldersgrupp' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.aldersgrupp)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.aldersgrupp)
																)
															)
															when 'original' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.original)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.original)
																)
															)
															when 'miljomarkning' then 
															(
																select md.Value
																from MetaDictionary md
																where md.MetaFieldId = md.MetaFieldId and
																(
																	(mf.MultiLanguageValue = 0 and md.MetaDictionaryId = book.miljomarkning)
																	or
																	(mf.MultiLanguageValue = 1 and md.MetaDictionaryId = lang.miljomarkning)
																)
															)
															else 'UNKNOWN'
														end [@value]
													from CatalogEntryEx_Book_Localization lang
													where ObjectId = book.ObjectId
													for xml path('Data'), type
												) 
											-- EnumMultiValue
											when mdt.Name = 'EnumMultiValue' then
												(
													case mf.Name
														when 'miljomarkning2' then 
														(
															select
																[Language] [@language],
																(
																	select mmvd.MetaDictionaryId [@key], md.Value [@value]
																	from MetaMultiValueDictionary mmvd
																		inner join MetaDictionary md
																			on mmvd.MetaDictionaryId = md.MetaDictionaryId
																	where 
																		(mf.MultiLanguageValue = 0 and mmvd.MetaKey = book.miljomarkning2)
																		or
																		(mf.MultiLanguageValue = 1 and mmvd.MetaKey = lang.miljomarkning2)
																	for xml path ('Item'), type
																)
															from CatalogEntryEx_Book_Localization lang
															where ObjectId = book.ObjectId
															for xml path('Data'), type
														)
														when '_ExcludedCatalogEntryMarkets' then 
														(
															select
																[Language] [@language],
																(
																	select mmvd.MetaDictionaryId [@key], md.Value [@value]
																	from MetaMultiValueDictionary mmvd
																		inner join MetaDictionary md
																			on mmvd.MetaDictionaryId = md.MetaDictionaryId
																	where 
																		(mf.MultiLanguageValue = 0 and mmvd.MetaKey = book._ExcludedCatalogEntryMarkets)
																		or
																		(mf.MultiLanguageValue = 1 and mmvd.MetaKey = lang._ExcludedCatalogEntryMarkets)
																	for xml path ('Item'), type
																)
															from CatalogEntryEx_Book_Localization lang
															where ObjectId = book.ObjectId
															for xml path('Data'), type
														)
														when 'lagerstatus' then 
														(
															select
																[Language] [@language],
																(
																	select mmvd.MetaDictionaryId [@key], md.Value [@value]
																	from MetaMultiValueDictionary mmvd
																		inner join MetaDictionary md
																			on mmvd.MetaDictionaryId = md.MetaDictionaryId
																	where 
																		(mf.MultiLanguageValue = 0 and mmvd.MetaKey = book.lagerstatus)
																		or
																		(mf.MultiLanguageValue = 1 and mmvd.MetaKey = lang.lagerstatus)
																	for xml path ('Item'), type
																)
															from CatalogEntryEx_Book_Localization lang
															where ObjectId = book.ObjectId
															for xml path('Data'), type
														)
													end					
												)
											-- Other types
											else 
												(
													select 
														[Language] [@language],
														case mf.Name
															when 'DisplayName' then case mf.MultiLanguageValue when 1 then lang.DisplayName else book.DisplayName end  
															when 'hanvisnings_isbn' then case mf.MultiLanguageValue when 1 then lang.hanvisnings_isbn else book.hanvisnings_isbn end
															when 'ean' then case mf.MultiLanguageValue when 1 then lang.ean else book.ean end
															when 'titel' then case mf.MultiLanguageValue when 1 then lang.titel else book.titel end
															when 'arbetstitel' then case mf.MultiLanguageValue when 1 then lang.arbetstitel else book.arbetstitel end
															when 'bandtyp' then case mf.MultiLanguageValue when 1 then lang.bandtyp else book.bandtyp end
															when 'forlag_id' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.forlag_id) else Convert(nvarchar, book.forlag_id) end
															when 'forlag' then case mf.MultiLanguageValue when 1 then lang.forlag else book.forlag end
															when 'distributor_id' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.distributor_id) else Convert(nvarchar, book.distributor_id) end
															when 'moms' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.moms) else Convert(nvarchar, book.moms) end
															when 'saljperiod' then case mf.MultiLanguageValue when 1 then lang.saljperiod else book.saljperiod end
															when 'utgivningsdatum' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.utgivningsdatum, 127) else Convert(nvarchar, book.utgivningsdatum, 127) end
															when 'upplagenummer' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.upplagenummer) else Convert(nvarchar, book.upplagenummer) end
															when 'tryckort' then case mf.MultiLanguageValue when 1 then lang.tryckort else book.tryckort end
															when 'omfang' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.omfang) else Convert(nvarchar, book.omfang) end
															when 'bredd' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.bredd) else Convert(nvarchar, book.bredd) end
															when 'hojd' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.hojd) else Convert(nvarchar, book.hojd) end
															when 'ryggbredd' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.ryggbredd) else Convert(nvarchar, book.ryggbredd) end
															when 'vikt' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.vikt) else Convert(nvarchar, book.vikt) end
															when 'prisgrupp' then case mf.MultiLanguageValue when 1 then lang.prisgrupp else book.prisgrupp end
															when 'antal_per_forpackning' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.antal_per_forpackning) else Convert(nvarchar, book.antal_per_forpackning) end
															when 'komponent' then case mf.MultiLanguageValue when 1 then lang.komponent else book.komponent end
															when 'rea_ar' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.rea_ar) else Convert(nvarchar, book.rea_ar) end
															when 'rea_fpris' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.rea_fpris) else Convert(nvarchar, book.rea_fpris) end
															when 'reapris_fran_datum' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.reapris_fran_datum, 127) else Convert(nvarchar, book.reapris_fran_datum, 127) end
															when 'originaltitel' then case mf.MultiLanguageValue when 1 then lang.originaltitel else book.originaltitel end
															when 'originalforlag' then case mf.MultiLanguageValue when 1 then lang.originalforlag else book.originalforlag end
															when 'serie' then case mf.MultiLanguageValue when 1 then lang.serie else book.serie end
															when 'lasordning' then case mf.MultiLanguageValue when 1 then lang.lasordning else book.lasordning end
															when 'lasordningval' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.lasordningval) else Convert(nvarchar, book.lasordningval) end
															when 'genre' then case mf.MultiLanguageValue when 1 then lang.genre else book.genre end
															when 'varugrupp' then case mf.MultiLanguageValue when 1 then lang.varugrupp else book.varugrupp end
															when 'saga' then case mf.MultiLanguageValue when 1 then lang.saga else book.saga end
															when 'katalogtext' then case mf.MultiLanguageValue when 1 then lang.katalogtext else book.katalogtext end
															when 'kommentarfalt' then case mf.MultiLanguageValue when 1 then lang.kommentarfalt else book.kommentarfalt end
															when 'internforfattare' then case mf.MultiLanguageValue when 1 then lang.internforfattare else book.internforfattare end
															when 'forsaljningsdatum' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.forsaljningsdatum, 127) else Convert(nvarchar, book.forsaljningsdatum, 127) end
															when 'recensionsdatum' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.recensionsdatum, 127) else Convert(nvarchar, book.recensionsdatum, 127) end
															when 'medarbetare' then case mf.MultiLanguageValue when 1 then lang.medarbetare else book.medarbetare end
															when 'bic' then case mf.MultiLanguageValue when 1 then lang.bic else book.bic end
															when 'bic_titel' then case mf.MultiLanguageValue when 1 then lang.bic_titel else book.bic_titel end
															when 'gymnasiekurs' then case mf.MultiLanguageValue when 1 then lang.gymnasiekurs else book.gymnasiekurs end
															when 'gymnasiekurs_titel' then case mf.MultiLanguageValue when 1 then lang.gymnasiekurs_titel else book.gymnasiekurs_titel end
															when 'gymnasieprogram' then case mf.MultiLanguageValue when 1 then lang.gymnasieprogram else book.gymnasieprogram end
															when 'gymnasieprogram_titel' then case mf.MultiLanguageValue when 1 then lang.gymnasieprogram_titel else book.gymnasieprogram_titel end
															when 'laromedelstyp' then case mf.MultiLanguageValue when 1 then lang.laromedelstyp else book.laromedelstyp end
															when 'laromedelstyp_titel' then case mf.MultiLanguageValue when 1 then lang.laromedelstyp_titel else book.laromedelstyp_titel end
															when 'utbildningsniva' then case mf.MultiLanguageValue when 1 then lang.utbildningsniva else book.utbildningsniva end
															when 'utbildningsniva_titel' then case mf.MultiLanguageValue when 1 then lang.utbildningsniva_titel else book.utbildningsniva_titel end
															when 'skolamne' then case mf.MultiLanguageValue when 1 then lang.skolamne else book.skolamne end
															when 'skolamne_titel' then case mf.MultiLanguageValue when 1 then lang.skolamne_titel else book.skolamne_titel end
															when 'utmarkelse' then case mf.MultiLanguageValue when 1 then lang.utmarkelse else book.utmarkelse end
															when 'utmarkelse_titel' then case mf.MultiLanguageValue when 1 then lang.utmarkelse_titel else book.utmarkelse_titel end
															when 'sprak' then case mf.MultiLanguageValue when 1 then lang.sprak else book.sprak end
															when 'katalogsignum' then case mf.MultiLanguageValue when 1 then lang.katalogsignum else book.katalogsignum end
															when 'amnesord' then case mf.MultiLanguageValue when 1 then lang.amnesord else book.amnesord end
															when 'link' then case mf.MultiLanguageValue when 1 then lang.link else book.link end
															when 'omslagsbild' then case mf.MultiLanguageValue when 1 then lang.omslagsbild else book.omslagsbild end
															when 'titel_sort' then case mf.MultiLanguageValue when 1 then lang.titel_sort else book.titel_sort end
															when 'istc' then case mf.MultiLanguageValue when 1 then lang.istc else book.istc end
															when 'tryckeri_producent' then case mf.MultiLanguageValue when 1 then lang.tryckeri_producent else book.tryckeri_producent end
															when 'ChangedForIndex' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.ChangedForIndex, 127) else Convert(nvarchar, book.ChangedForIndex, 127) end
															when 'fakturadatum' then case mf.MultiLanguageValue when 1 then Convert(nvarchar, lang.fakturadatum, 127) else Convert(nvarchar, book.fakturadatum, 127) end
															when 'innehall' then case mf.MultiLanguageValue when 1 then lang.innehall else book.innehall end

															when 'har_katalogtext' then case mf.MultiLanguageValue 
																when 1 then case when lang.har_katalogtext = 1 then 'True' else 'False' end
																else case when book.har_katalogtext = 1 then 'True' else 'False' end
															end
															when 'har_saga' then case mf.MultiLanguageValue 
																when 1 then case when lang.har_saga = 1 then 'True' else 'False' end
																else case when book.har_saga = 1 then 'True' else 'False' end
															end
															when 'har_omslagsbild' then case mf.MultiLanguageValue 
																when 1 then case when lang.har_omslagsbild = 1 then 'True' else 'False' end
																else case when book.har_omslagsbild = 1 then 'True' else 'False' end
															end
															
															when 'dewey' then case mf.MultiLanguageValue when 1 then lang.dewey else book.dewey end
															when 'thema' then case mf.MultiLanguageValue when 1 then lang.thema else book.thema end
															when 'thema_titel' then case mf.MultiLanguageValue when 1 then lang.thema_titel else book.thema_titel end
															when 'illustreradesidor' then case mf.MultiLanguageValue when 1 then lang.illustreradesidor else book.illustreradesidor end
															when 'omslagsfarg' then case mf.MultiLanguageValue when 1 then lang.omslagsfarg else book.omslagsfarg end
															when 'omslag_beskrivning' then case mf.MultiLanguageValue when 1 then lang.omslag_beskrivning else book.omslag_beskrivning end
															when 'omslagstitel' then case mf.MultiLanguageValue when 1 then lang.omslagstitel else book.omslagstitel end
															when 'nyckelord' then case mf.MultiLanguageValue when 1 then lang.nyckelord else book.nyckelord end
															when 'serie_titel' then case mf.MultiLanguageValue when 1 then lang.serie_titel else book.serie_titel end
															else 'UNKNOWN'
														end [@value]
													from CatalogEntryEx_Book_Localization lang
													where ObjectId = book.ObjectId
													for xml path('Data'), type
												)
										end
									from MetaField mf
										inner join MetaClassMetaFieldRelation mcmfr
											on mf.MetaFieldId = mcmfr.MetaFieldId
										inner join MetaDataType mdt
											on mf.DataTypeId = mdt.DataTypeId
									where 
										mf.SystemMetaClassId = 0
										and mcmfr.Enabled = 1 
										and mcmfr.MetaClassId = (select MetaClassId from MetaClass where [Namespace] = 'Mediachase.Commerce.Catalog.User' and Name = 'Book')
									for xml path ('MetaField'), root('MetaFields'), type
								) 
								for xml path ('MetaData'), type
							),
							-- Variation
							(
								select 
									MaxQuantity, 
									MinQuantity,
									case TrackInventory when 1 then 'True' else 'False' end TrackInventory,
									Convert(nvarchar, [Weight]) [Weight]
								from Variation
								where CatalogEntryId = ce.CatalogEntryId
								for xml path ('Variation'), root ('VariationInfo'), type
							),
							-- Seo
							(
								select 
									LanguageCode,
									Uri,
									Title,
									Keywords,
									UriSegment
								from CatalogItemSeo
								where CatalogEntryId = ce.CatalogEntryId
								for xml path ('Seo'), root ('SeoInfo'), type
							)
						from CatalogEntry ce
							inner join CatalogEntryEx_Book book
								on ce.CatalogEntryId = book.ObjectId
							inner join NodeEntryRelation ner
								on ce.CatalogEntryId = ner.CatalogEntryId
							inner join CatalogNode n
								on ner.CatalogNodeId = n.CatalogNodeId
						where n.Code = @CatalogNodeCode and ce.CatalogId = c.CatalogId
						for xml path('Entry'), type
					)
				for xml path ('Entries'), type
			),
			-- Relations
			(
				select
				(
					select 
						ce.Code [EntryCode],
						cn.Code [NodeCode],
						ner.SortOrder
					from CatalogNode cn
						inner join NodeEntryRelation ner
							on cn.CatalogNodeId = ner.CatalogNodeId
						inner join CatalogEntry ce
							on ner.CatalogEntryId = ce.CatalogEntryId
					where cn.CatalogId = c.CatalogId and cn.Code = @CatalogNodeCode
					for xml path('NodeEntryRelation'), type
				)
				for xml path ('Relations'), type
			),
			-- Associations
			(
				select
					Count(*) [@totalCount],
					(
						select 
							ca.AssociationName [Name],
							ca.AssociationDescription [Description],
							ca.SortOrder,
							ce.Code,
							(
								select 
									ce.Code [CatalogEntryCode],
									cea.SortOrder,
									cea.AssociationTypeId [Type]
								from CatalogEntryAssociation cea
									inner join CatalogEntry ce
										on cea.CatalogEntryId = ce.CatalogEntryId
									inner join AssociationType at
										on cea.AssociationTypeId = at.AssociationTypeId
								where cea.CatalogAssociationId = ca.CatalogAssociationId
								for xml path ('Association'), type
							)
						from CatalogNode cn
							inner join NodeEntryRelation ner
								on cn.CatalogNodeId = ner.CatalogNodeId
							inner join CatalogEntry ce
								on ner.CatalogEntryId = ce.CatalogEntryId
							inner join CatalogAssociation ca
								on ca.CatalogEntryId = ce.CatalogEntryId
							where cn.Code = @CatalogNodeCode
						for xml path('CatalogAssociation'), type
					)
				from CatalogNode cn
					inner join NodeEntryRelation ner
						on cn.CatalogNodeId = ner.CatalogNodeId
					inner join CatalogEntry ce
						on ner.CatalogEntryId = ce.CatalogEntryId
					inner join CatalogAssociation ca
						on ca.CatalogEntryId = ce.CatalogEntryId
				where cn.Code = @CatalogNodeCode
				for xml path ('Associations'), type
			)
		from [Catalog] c
		where c.CatalogId in (Select CatalogId from CatalogNode where Code = @CatalogNodeCode)
		order by c.SortOrder
		for xml path ('Catalog'), type
	)
for xml path ('Catalogs'))
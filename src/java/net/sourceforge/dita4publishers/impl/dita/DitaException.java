/**
 * Copyright 2009, 2010 DITA for Publishers project (dita4publishers.sourceforge.net)  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at     http://www.apache.org/licenses/LICENSE-2.0  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License. 
 */
package net.sourceforge.dita4publishers.impl.dita;

/**
 * Violation of DITA-defined rules or DITA-specific
 * processing failure.
 * <p>NOTE: Extends runtime exception so that 
 * instances can be constructed statically.</p>
 */
public class DitaException extends RuntimeException {

	private static final long serialVersionUID = -1L;

	/**
	 * @param message
	 */
	public DitaException(String message) {
		super(message);
	}

}
